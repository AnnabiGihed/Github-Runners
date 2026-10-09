#requires -Version 5.1
function Find-RunnerPowerShell {
    param([string]$PowerShellPath)
    $candidates=@()
    if ($PowerShellPath) { $candidates=@($PowerShellPath) }
    else {
        if ($PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.PSVersion -ge [version]'7.4') { $candidates+= (Get-Process -Id $PID).Path }
        $command=Get-Command pwsh.exe -ErrorAction SilentlyContinue
        if ($command) { $candidates+=$command.Source }
        foreach ($directory in @($env:ProgramFiles,$env:LOCALAPPDATA)) {
            if ($directory) { $candidates+=Join-Path $directory 'PowerShell/7/pwsh.exe' }
        }
        # Reuse the runtime already selected for this project's installed supervisor.
        $task=Get-ScheduledTask -TaskName EphemeralGitHubRunners -ErrorAction SilentlyContinue
        if ($task) {
            foreach ($action in $task.Actions) {
                if ([IO.Path]::GetFileName($action.Execute) -ieq 'pwsh.exe') { $candidates+=$action.Execute }
                elseif ([IO.Path]::GetFileName($action.Execute) -ieq 'wscript.exe' -and $action.Arguments -match '//E:JScript\s+"[^"]+"\s+"([^"]+pwsh\.exe)"') { $candidates+=$Matches[1] }
            }
        }
    }
    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        if (-not $candidate -or -not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        try {
            $versionText=& $candidate -NoLogo -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
            if ($LASTEXITCODE -eq 0 -and [version]($versionText | Select-Object -Last 1) -ge [version]'7.4') { return [IO.Path]::GetFullPath($candidate) }
        } catch { continue }
    }
    throw 'PowerShell 7.4 or newer was not found. Install PowerShell 7, or supply -PowerShellPath with the full path to pwsh.exe. Windows PowerShell 5.1 can launch the app but cannot host it.'
}
