#requires -Version 7.4
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$testRoot=Join-Path $root ('.local/tests/desktop-'+[guid]::NewGuid().ToString('N'))
function Assert([bool]$Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
function Reject([scriptblock]$Body,[string]$Message) { $rejected=$false;try { & $Body | Out-Null } catch { $rejected=$true };Assert $rejected $Message }
try {
    foreach ($dir in @('scripts/desktop','scripts/config','scripts/github','scripts/controller','scripts/host','config','.local/controller','.local/secrets')) { New-Item -ItemType Directory -Path (Join-Path $testRoot $dir) -Force | Out-Null }
    foreach ($file in @('scripts/desktop/RunnerDesktop.psm1','scripts/config/Test-RunnerConfiguration.ps1','scripts/controller/RunnerDiagnostics.psm1','scripts/github/Protect-RunnerAppKey.ps1')) { Copy-Item -LiteralPath (Join-Path $root $file) -Destination (Join-Path $testRoot $file) }
    # Deliberate API substitute only in a disposable copy of the repo, never production.
    @'
param($ConfigPath)
$config=Get-Content $ConfigPath -Raw | ConvertFrom-Json
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (Test-Path (Join-Path $root '.local/fail-access')) { throw 'Fixture API rejection' }
foreach ($target in $config.targets) { [pscustomobject]@{Target=$target.id;PrivateRepository=(-not (Test-Path (Join-Path $root '.local/public-repo')))} }
'@ | Set-Content (Join-Path $testRoot 'scripts/github/Test-RunnerGitHubAccess.ps1')
    '[pscustomobject]@{ControllerLockHeld=$false;SupervisorLockHeld=$false;RecordedSlots=0}' | Set-Content (Join-Path $testRoot 'scripts/host/Test-RunnerService.ps1')
    Import-Module (Join-Path $testRoot 'scripts/desktop/RunnerDesktop.psm1') -Force
    $rsa=[Security.Cryptography.RSA]::Create(2048)
    try { $source=Join-Path $testRoot 'fixture.pem';[IO.File]::WriteAllText($source,$rsa.ExportRSAPrivateKeyPem()) } finally { $rsa.Dispose() }
    $request=[pscustomobject]@{id='fixture-personal';scope='repository';owner='FixtureOwner';repository='FixtureRepo';appId=1L;installationId=2L;labels=@('fixture');maxRunners=2;trustedPublicWorkflows=$false;keySource=$source}
    $configPath=Join-Path $testRoot '.local/targets.json'
    New-Item (Join-Path $testRoot '.local/fail-access') -ItemType File | Out-Null
    Reject { Save-DesktopTarget $request } 'Failed API validation should reject saving.'
    Assert (-not (Test-Path $configPath)) 'Failed first save created a configuration.'
    Assert (@(Get-ChildItem (Join-Path $testRoot '.local/secrets') -File).Count -eq 0) 'Failed validation leaked an imported key.'
    Remove-Item (Join-Path $testRoot '.local/fail-access')
    Save-DesktopTarget $request | Out-Null
    $config=Get-DesktopTargets
    Assert ($config.targets.Count -eq 1) 'First target was not saved.'
    Assert (Test-Path (Join-Path $testRoot $config.targets[0].privateKeyFile)) 'Imported key missing.'
    $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $acl=Get-Acl (Join-Path $testRoot $config.targets[0].privateKeyFile)
    Assert ($acl.AreAccessRulesProtected -and @($acl.Access | Where-Object { $_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value -ne $sid }).Count -eq 0) 'Imported key is not private.'
    $before=[IO.File]::ReadAllText($configPath)
    $request.keySource='';$request.maxRunners=5
    Reject { Save-DesktopTarget $request } 'Over-capacity edit accepted.'
    Assert ([IO.File]::ReadAllText($configPath) -ceq $before) 'Rejected edit changed working configuration.'
    $request.maxRunners=2;$request.owner='DifferentOwner'
    Reject { Save-DesktopTarget $request } 'Existing target identity change accepted.'
    $request.owner='FixtureOwner';Save-DesktopTarget $request | Out-Null
    Assert ((Get-DesktopTargets).targets[0].privateKeyFile -eq $config.targets[0].privateKeyFile) 'Blank key field did not retain existing key.'
    New-Item (Join-Path $testRoot '.local/public-repo') -ItemType File | Out-Null
    Reject { Save-DesktopTarget $request } 'Public repository without trust acknowledgement accepted.'
    Remove-Item (Join-Path $testRoot '.local/public-repo')
    $org=[pscustomobject]@{id='fixture-org';scope='organization';owner='FixtureOrganization';repository=$null;appId=3L;installationId=4L;labels=@('fixture-org');maxRunners=2;trustedPublicWorkflows=$false;keySource=$source}
    Save-DesktopTarget $org | Out-Null
    Assert ((Get-DesktopTargets).targets.Count -eq 2) 'Adding organization overwrote personal target.'
    $statePath=Join-Path $testRoot '.local/controller/state.json'
    '{"slots":[]}' | Set-Content $statePath
    Reject { Remove-DesktopTarget 'fixture-org' } 'Removal without persistent stop accepted.'
    New-Item (Join-Path $testRoot '.local/controller/stop') -ItemType File | Out-Null
    '{"slots":[{"name":"busy-fixture"}]}' | Set-Content $statePath
    Reject { Remove-DesktopTarget 'fixture-org' } 'Removal with retained environment accepted.'
    '{"slots":[]}' | Set-Content $statePath
    Remove-DesktopTarget 'fixture-org' | Out-Null
    Assert ((Get-DesktopTargets).targets.Count -eq 1) 'Drained target removal failed.'
    Reject { Remove-DesktopTarget 'fixture-personal' } 'Removing final target accepted.'
    # Exercise the actual worker's fresh-start branch with fixture-only dependencies.
    Copy-Item (Join-Path $root 'config/runner-resources.json') (Join-Path $testRoot 'config/runner-resources.json')
    Copy-Item (Join-Path $root 'scripts/config/Test-RunnerResources.ps1') (Join-Path $testRoot 'scripts/config/Test-RunnerResources.ps1')
    '''{"CPUs":8,"EngineMemoryGiB":16}''' | Set-Content (Join-Path $testRoot 'scripts/host/Test-RunnerHost.ps1')
    '''fixture installation complete''' | Set-Content (Join-Path $testRoot 'scripts/host/Install-RunnerScheduledTask.ps1')
    @'
param([switch]$Resume)
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
New-Item (Join-Path $root '.local/started-fixture') -ItemType File | Out-Null
'@ | Set-Content (Join-Path $testRoot 'scripts/host/Start-RunnerService.ps1')
    'throw "Fresh setup must not call restart before state exists."' | Set-Content (Join-Path $testRoot 'scripts/host/Restart-RunnerService.ps1')
    $worker=Join-Path $testRoot 'scripts/desktop/Invoke-DesktopAction.ps1'
    # This CLI substitute is appended to the fixture worker's initialization only.
    $workerText=[IO.File]::ReadAllText((Join-Path $root 'scripts/desktop/Invoke-DesktopAction.ps1'))
    $workerText=$workerText.Replace("Set-Location -LiteralPath `$root","Set-Location -LiteralPath `$root`nfunction docker { `$global:LASTEXITCODE=0; return '{}' }")
    [IO.File]::WriteAllText($worker,$workerText)
    Remove-Item -LiteralPath $statePath
    $psi=[Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardInput=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    foreach ($arg in @('-NoProfile','-File',$worker,'-Action','Setup')) { $psi.ArgumentList.Add($arg) }
    $process=[Diagnostics.Process]::Start($psi)
    try {
        $out=$process.StandardOutput.ReadToEndAsync();$err=$process.StandardError.ReadToEndAsync()
        $process.StandardInput.Write(($request | ConvertTo-Json -Depth 10));$process.StandardInput.Close()
        if (-not $process.WaitForExit(30000)) { $process.Kill($true);throw 'Fixture desktop worker timed out.' }
        Assert ($process.ExitCode -eq 0) ("Fresh fixture setup worker failed: "+$err.Result)
        Assert (Test-Path (Join-Path $testRoot '.local/started-fixture')) 'Fresh setup did not request start.'
    } finally { $process.Dispose() }
    'Desktop tests passed: rollback, protected keys, capacity, identity, key reuse, public acknowledgement, organization addition, guarded removal and fresh-setup worker routing. API/Docker/service effects were mocked in a disposable copy.'
} finally {
    Remove-Module RunnerDesktop -ErrorAction SilentlyContinue
    $resolved=[IO.Path]::GetFullPath($testRoot)
    $allowed=[IO.Path]::GetFullPath((Join-Path $root '.local/tests'))+[IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Test cleanup outside workspace rejected.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
