#requires -Version 7.4
[CmdletBinding()]
param([switch]$Docker)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot '../scripts/controller/RunnerDiagnostics.psm1') -Force
$samples=@(
    'ghs_ABCDEF1234567890',
    'github_pat_ABCD1234',
    'Authorization: Bearer example-secret',
    '{"token":"registration-secret"}',
    "-----BEGIN RSA PRIVATE KEY-----`nprivate-material`n-----END RSA PRIVATE KEY-----",
    'eyJhbGciOiJSUzI1NiJ9.eyJpc3MiOiIxIn0.signature',
    'https://example.invalid?token=sensitive'
)
foreach ($sample in $samples) {
    $result=Protect-RunnerDiagnosticText $sample
    if ($result -notmatch 'REDACTED' -or $result -eq $sample -or $result -match 'private-material|example-secret|registration-secret|signature') { throw 'Diagnostic secret redaction failed.' }
}
if ((Protect-RunnerDiagnosticText 'Runner ready: exit 0') -ne 'Runner ready: exit 0') { throw 'Ordinary diagnostic text changed.' }
$path=Join-Path $PSScriptRoot '../.local/tests/diagnostics'
Initialize-RunnerDiagnosticDirectory -Path $path
$old=Join-Path $path 'pc-retention-old.diag.txt'
Set-Content -LiteralPath $old -Value 'sanitized fixture'
(Get-Item -LiteralPath $old).LastWriteTimeUtc=[DateTime]::UtcNow.AddDays(-8)
$unrelated=Join-Path $path 'keep.txt'
Set-Content -LiteralPath $unrelated -Value 'unrelated fixture'
Limit-RunnerDiagnostics -Path $path
if ((Test-Path $old) -or -not (Test-Path $unrelated)) { throw 'Retention ownership/age test failed.' }
Remove-Item -LiteralPath $unrelated
Write-Output 'Passed: token/JWT/key/sensitive-line redaction, ordinary text, age retention, unrelated-file preservation.'
if ($Docker) {
    $name="pc-diag-test-$([guid]::NewGuid().ToString('N').Substring(0,12))"
    try {
        & docker run --name $name --network none --cap-drop ALL --security-opt no-new-privileges --entrypoint bash local/ephemeral-github-runner:dev -c 'mkdir -p /home/runner/_diag; for i in $(seq 1 9); do head -c 262144 /dev/zero | tr "\000" x > /home/runner/_diag/Worker_${i}.log; done; printf "\nRunner ready\nAuthorization: Bearer fixture-secret\n" >> /home/runner/_diag/Worker_9.log' | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Diagnostic fixture container failed.' }
        Save-RunnerDiagnostics -Container $name -Path $path
        $saved=Get-Content -LiteralPath (Join-Path $path "$name.diag.txt") -Raw
        if ($saved -notmatch 'Runner ready' -or $saved -notmatch 'REDACTED' -or $saved -match 'fixture-secret') { throw 'Stopped-container diagnostic persistence/redaction failed.' }
        if ((Get-Item -LiteralPath (Join-Path $path "$name.diag.txt")).Length -gt 2MB) { throw 'Diagnostic byte cap exceeded.' }
        Write-Output 'Passed: stopped-container tar diagnostics persisted with fixture secret removed.'
    } finally {
        & docker rm -f -v $name 2>$null | Out-Null
        $fixture=Join-Path $path "$name.diag.txt"
        if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture }
    }
}
