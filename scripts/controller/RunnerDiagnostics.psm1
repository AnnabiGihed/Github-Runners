#requires -Version 7.4
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Protect-RunnerDiagnosticText {
    param([AllowEmptyString()][string]$Text)
    $Text=[regex]::Replace($Text,'(?s)-----BEGIN [^-]*PRIVATE KEY-----.*?-----END [^-]*PRIVATE KEY-----','[REDACTED PRIVATE KEY]')
    $Text=$Text -replace '(gh[pousr]_[A-Za-z0-9]+|github_pat_[A-Za-z0-9_]+)','[REDACTED TOKEN]'
    $Text=$Text -replace '\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b','[REDACTED JWT]'
    $Text=$Text -replace '(?im)^.*(?:authorization|access.?token|registration.?token|password|secret|credential|"token"|[?&]token=).*$','[REDACTED SENSITIVE LINE]'
    return $Text
}
function Initialize-RunnerDiagnosticDirectory {
    param([Parameter(Mandatory)][string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    if ($IsWindows) {
        $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
        $acl=Get-Acl -LiteralPath $Path
        $acl.SetAccessRuleProtection($true,$false)
        foreach ($rule in @($acl.Access)) { $null=$acl.RemoveAccessRuleSpecific($rule) }
        $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid,'FullControl','ContainerInherit,ObjectInherit','None','Allow'))
        [IO.FileSystemAclExtensions]::SetAccessControl([IO.DirectoryInfo]::new($Path),$acl)
        $actual=Get-Acl -LiteralPath $Path
        if (-not $actual.AreAccessRulesProtected) { throw 'Diagnostic ACL inheritance is enabled.' }
        foreach ($rule in $actual.Access) {
            if ($rule.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value -ne $sid.Value) { throw 'Unexpected diagnostic directory access rule.' }
        }
    }
}
function Limit-RunnerDiagnostics {
    param([Parameter(Mandatory)][string]$Path)
    # Files are project-owned outputs in one protected directory; no recursive deletion.
    $files=@(Get-ChildItem -LiteralPath $Path -File | Where-Object Name -match '^(pc-.*\.diag\.txt|supervisor(?:\.1)?\.log)$' | Sort-Object LastWriteTimeUtc -Descending)
    $total=0L
    foreach ($file in $files) {
        $total+=$file.Length
        if ($file.LastWriteTimeUtc -lt [DateTime]::UtcNow.AddDays(-7) -or $total -gt 200MB) { Remove-Item -LiteralPath $file.FullName }
    }
}
function Save-RunnerDiagnostics {
    param([Parameter(Mandatory)][string]$Container, [Parameter(Mandatory)][string]$Path)
    if ($Container -notmatch '^pc-[a-z0-9-]+$') { throw 'Invalid owned runner name.' }
    # Stream tar bytes into bounded memory; docker cp also works for stopped containers.
    # No raw diagnostic file, credential file or job workspace is copied to the host.
    $psi=[Diagnostics.ProcessStartInfo]::new('docker')
    foreach ($arg in @('cp',"${Container}:/home/runner/_diag/.",'-')) { $psi.ArgumentList.Add($arg) }
    $psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $process=[Diagnostics.Process]::Start($psi)
    $stderr=$process.StandardError.ReadToEndAsync()
    $archive=[IO.MemoryStream]::new()
    try {
        $buffer=[byte[]]::new(65536)
        while (($count=$process.StandardOutput.BaseStream.Read($buffer,0,$buffer.Length)) -gt 0) {
            if ($archive.Length+$count -gt 64MB) { $process.Kill();throw 'Diagnostic archive exceeds memory bound; preserve environment for inspection.' }
            $archive.Write($buffer,0,$count)
        }
        $process.WaitForExit()
        $safe=''
        if ($process.ExitCode -eq 0) {
            $archive.Position=0
            $reader=[System.Formats.Tar.TarReader]::new($archive,$true)
            try {
                while ($entry=$reader.GetNextEntry()) {
                    if ($entry.EntryType -notin @([System.Formats.Tar.TarEntryType]::RegularFile,[System.Formats.Tar.TarEntryType]::V7RegularFile) -or $entry.Name -notmatch '(?:^|/)(Runner|Worker)_[^/]+\.log$') { continue }
                    $bytes=[IO.MemoryStream]::new()
                    try {
                        $entry.DataStream.CopyTo($bytes)
                        $data=$bytes.ToArray()
                        $start=[Math]::Max(0,$data.Length-262144)
                        $text=[Text.Encoding]::UTF8.GetString($data,$start,$data.Length-$start)
                        $safe+="`nDiagnostic file: $([IO.Path]::GetFileName($entry.Name))`n"+(Protect-RunnerDiagnosticText $text)
                    } finally { $bytes.Dispose() }
                }
            } finally { $reader.Dispose() }
        } else {
            $text=& docker logs --tail 500 $Container 2>$null
            if ($LASTEXITCODE -ne 0) { throw 'Diagnostic collection unavailable; retain runner for retry.' }
            $safe=Protect-RunnerDiagnosticText ($text -join "`n")
        }
    } finally { $archive.Dispose();$process.Dispose() }
    $encoded=[Text.Encoding]::UTF8.GetBytes($safe)
    $maximum=2MB-16
    if ($encoded.Length -gt $maximum) { $safe=[Text.Encoding]::UTF8.GetString($encoded,$encoded.Length-$maximum,$maximum) }
    Set-Content -LiteralPath (Join-Path $Path "$Container.diag.txt") -Value $safe -Encoding utf8 -NoNewline
    Limit-RunnerDiagnostics -Path $Path
}
Export-ModuleMember -Function Protect-RunnerDiagnosticText,Initialize-RunnerDiagnosticDirectory,Limit-RunnerDiagnostics,Save-RunnerDiagnostics
