#requires -Version 7.4
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:Root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $script:Root 'scripts/controller/RunnerDiagnostics.psm1') -Force

function Get-DesktopTargets {
    $path=Join-Path $script:Root '.local/targets.json'
    if (Test-Path -LiteralPath $path) { return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json }
    return [pscustomobject]@{schemaVersion=1;hostMaxRunners=4;targets=@()}
}

function Save-DesktopTarget {
    param([Parameter(Mandatory)]$InputTarget)
    # Serialize GUI writers and detect external edits before committing the validated candidate.
    $ui=Join-Path $script:Root '.local/desktop'
    Initialize-RunnerDiagnosticDirectory -Path $ui
    $lock=[IO.File]::Open((Join-Path $ui 'config.lock'),'OpenOrCreate','ReadWrite','None')
    $temporary=$null;$newKey=$null;$committed=$false
    try {
        $path=Join-Path $script:Root '.local/targets.json'
        $original=if (Test-Path $path) { [IO.File]::ReadAllText($path) } else { $null }
        $config=Get-DesktopTargets
        $old=@($config.targets | Where-Object id -eq $InputTarget.id)
        if ($old.Count -gt 1) { throw 'Duplicate target ID in existing configuration.' }
        if ($old.Count -and ($old[0].scope -ne $InputTarget.scope -or $old[0].owner -ne $InputTarget.owner -or $old[0].repository -ne $InputTarget.repository)) { throw 'An existing target ID cannot change identity. Add a distinct target instead.' }
        if ($InputTarget.id -notmatch '^[a-z0-9][a-z0-9-]{0,47}$') { throw 'Use a lowercase target ID containing letters, numbers and hyphens.' }
        $target=[pscustomobject]@{
            id=[string]$InputTarget.id;scope=[string]$InputTarget.scope;owner=[string]$InputTarget.owner
            repository=if ($InputTarget.scope -eq 'organization') { $null } else { [string]$InputTarget.repository }
            appId=[long]$InputTarget.appId;installationId=[long]$InputTarget.installationId
            privateKeyFile=if ($old.Count) { $old[0].privateKeyFile } else { ".local/secrets/$($InputTarget.id).pem" }
            labels=@($InputTarget.labels);maxRunners=[int]$InputTarget.maxRunners
            trustedPublicWorkflows=[bool]$InputTarget.trustedPublicWorkflows
        }
        # Preserve advanced scaling options when editing an existing target in the GUI.
        foreach ($field in @('scalingMode','pollSeconds')) {
            if ($old.Count -and $old[0].PSObject.Properties[$field]) { $target | Add-Member -NotePropertyName $field -NotePropertyValue $old[0].$field }
        }
        if ($InputTarget.PSObject.Properties['scalingMode']) { $target | Add-Member -NotePropertyName scalingMode -NotePropertyValue $InputTarget.scalingMode -Force }
        $config.targets=@($config.targets | Where-Object id -ne $target.id)+@($target)
        $temporary=Join-Path $ui ("candidate-"+[guid]::NewGuid().ToString('N')+'.json')
        $config | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $temporary -Encoding utf8
        & (Join-Path $script:Root 'scripts/config/Test-RunnerConfiguration.ps1') -Path $temporary | Out-Null
        if (-not [string]::IsNullOrWhiteSpace([string]$InputTarget.keySource)) {
            $source=Get-Item -LiteralPath $InputTarget.keySource
            if ($source.PSIsContainer -or $source.LinkType -or $source.Length -gt 64KB) { throw 'Select a regular GitHub App PEM file smaller than 64 KiB.' }
            $rsa=[Security.Cryptography.RSA]::Create()
            try { $rsa.ImportFromPem([IO.File]::ReadAllText($source.FullName)); $null=$rsa.ExportParameters($true) }
            catch { throw 'The selected file is not a usable RSA private key.' }
            finally { $rsa.Dispose() }
            $secretDir=Join-Path $script:Root '.local/secrets'
            Initialize-RunnerDiagnosticDirectory -Path $secretDir
            # A new file preserves the old working key if validation fails or jobs are draining.
            $target.privateKeyFile=".local/secrets/$($target.id)-$([guid]::NewGuid().ToString('N')).pem"
            $newKey=Join-Path $script:Root $target.privateKeyFile
            [IO.File]::Copy($source.FullName,$newKey,$false)
            & (Join-Path $script:Root 'scripts/github/Protect-RunnerAppKey.ps1') -Path $newKey | Out-Null
        } elseif (-not $old.Count) { throw 'Select the GitHub App private-key PEM file for a new target.' }
        $config | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $temporary -Encoding utf8
        $access=@(& (Join-Path $script:Root 'scripts/github/Test-RunnerGitHubAccess.ps1') -ConfigPath $temporary)
        if ($target.scope -eq 'repository' -and -not $target.trustedPublicWorkflows -and @($access | Where-Object { $_.Target -eq $target.id -and $_.PrivateRepository -eq $false }).Count) { throw 'This repository is public. Review its trusted workflow policy and explicitly authorize public workflows before saving.' }
        $now=if (Test-Path $path) { [IO.File]::ReadAllText($path) } else { $null }
        if ($now -cne $original) { throw 'Configuration changed during validation. Reload targets and retry.' }
        if ($null -ne $original) { [IO.File]::WriteAllText((Join-Path $ui 'targets.previous.json'),$original) }
        [IO.File]::Move($temporary,$path,$true)
        $committed=$true
        return "Saved and verified $($target.id). Apply configuration to activate it."
    } finally {
        if ($temporary -and (Test-Path $temporary)) { Remove-Item -LiteralPath $temporary }
        if (-not $committed -and $newKey -and (Test-Path $newKey)) { Remove-Item -LiteralPath $newKey }
        $lock.Dispose()
    }
}

function Remove-DesktopTarget {
    param([Parameter(Mandatory)][string]$Id)
    $status=& (Join-Path $script:Root 'scripts/host/Test-RunnerService.ps1')
    if ($status.ControllerLockHeld -or $status.SupervisorLockHeld -or $status.RecordedSlots -ne 0) { throw 'Stop and drain all runners before removing a target. Refresh status until no slots remain.' }
    $ui=Join-Path $script:Root '.local/desktop';Initialize-RunnerDiagnosticDirectory -Path $ui
    $lock=[IO.File]::Open((Join-Path $ui 'config.lock'),'OpenOrCreate','ReadWrite','None')
    $controllerLock=$null;$supervisorLock=$null
    try {
        $stateDir=Join-Path $script:Root '.local/controller'
        if (-not (Test-Path (Join-Path $stateDir 'stop'))) { throw 'A persistent stop request is required before removing a target.' }
        $supervisorLock=[IO.File]::Open((Join-Path $stateDir 'supervisor.lock'),'OpenOrCreate','ReadWrite','None')
        $controllerLock=[IO.File]::Open((Join-Path $stateDir 'controller.lock'),'OpenOrCreate','ReadWrite','None')
        $state=Get-Content (Join-Path $stateDir 'state.json') -Raw | ConvertFrom-Json
        if (@($state.slots).Count) { throw 'Runner state still contains environments; removal is blocked.' }
        $config=Get-DesktopTargets
        if (-not @($config.targets | Where-Object id -ceq $Id).Count) { throw 'Target not found.' }
        $config.targets=@($config.targets | Where-Object id -cne $Id)
        if (-not $config.targets.Count) { throw 'Keep at least one configured target; leave the service stopped to disable all runners.' }
        $path=Join-Path $script:Root '.local/targets.json'
        $temp=Join-Path $ui 'remove-candidate.json'
        try {
            $config | ConvertTo-Json -Depth 15 | Set-Content $temp -Encoding utf8
            & (Join-Path $script:Root 'scripts/config/Test-RunnerConfiguration.ps1') -Path $temp | Out-Null
            [IO.File]::Copy($path,(Join-Path $ui 'targets.previous.json'),$true)
            [IO.File]::Move($temp,$path,$true)
        } finally { if (Test-Path $temp) { Remove-Item -LiteralPath $temp } }
        return 'Target removed from configuration. Its key was retained for deliberate rotation/revocation.'
    } finally { if ($controllerLock) { $controllerLock.Dispose() };if ($supervisorLock) { $supervisorLock.Dispose() };$lock.Dispose() }
}

Export-ModuleMember -Function Get-DesktopTargets,Save-DesktopTarget,Remove-DesktopTarget
