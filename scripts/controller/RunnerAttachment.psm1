#requires -Version 7.4
# Bootstrap delivery attaches a Docker CLI to the runner's stdin. `docker start -a`
# always forwards the signals it receives to the container, and Windows turns console
# control events (window close, Ctrl+C/Break) into such signals. The CLI therefore gets
# its own windowless console: closing or interrupting the supervisor's console must not
# reach a busy job. A hard-terminated CLI cannot forward anything, so supervisor crashes
# leave the container running for the next supervisor to reconcile.
function Start-RunnerAttachment {
    param([Parameter(Mandatory)][string]$Container,[string]$Docker='docker')
    $psi=[Diagnostics.ProcessStartInfo]::new($Docker)
    foreach ($arg in @('start','-ai',$Container)) { $psi.ArgumentList.Add($arg) }
    $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
    $psi.RedirectStandardInput=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $process=[Diagnostics.Process]::Start($psi)
    $out=$process.StandardOutput.ReadToEndAsync();$err=$process.StandardError.ReadToEndAsync()
    return @{process=$process;stdout=$out;stderr=$err}
}
Export-ModuleMember -Function Start-RunnerAttachment
