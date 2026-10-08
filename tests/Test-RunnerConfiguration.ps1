$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$validator = Join-Path $repoRoot 'scripts/config/Test-RunnerConfiguration.ps1'
$example = Join-Path $repoRoot 'config/targets.example.json'
& $validator -Path $example -AllowIncomplete | Out-Null
function Assert-Rejected {
    param([scriptblock]$Action)
    $rejected = $false
    try { & $Action | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw 'Invalid configuration was accepted.' }
}
Assert-Rejected { & $validator -Path $example }
$fixturePath = Join-Path ([IO.Path]::GetTempPath()) ("runner-config-test-" + [guid]::NewGuid().ToString('N') + '.json')
try {
    foreach ($field in @('scalingMode','pollSeconds')) {
        $fixture=Get-Content $example -Raw | ConvertFrom-Json
        $value=if ($field -eq 'scalingMode') { 'invalid' } else { 1 }
        $fixture.targets[0] | Add-Member -NotePropertyName $field -NotePropertyValue $value -Force
        $fixture | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $fixturePath
        Assert-Rejected { & $validator -Path $fixturePath -AllowIncomplete }
    }
    $fixture = Get-Content $example -Raw | ConvertFrom-Json
    $fixture.targets[1].id = $fixture.targets[0].id
    $fixture | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $fixturePath
    Assert-Rejected { & $validator -Path $fixturePath -AllowIncomplete }
    $fixture = Get-Content $example -Raw | ConvertFrom-Json
    $fixture.hostMaxRunners = 3
    $fixture | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $fixturePath
    Assert-Rejected { & $validator -Path $fixturePath -AllowIncomplete }
    $fixture = Get-Content $example -Raw | ConvertFrom-Json
    $fixture.targets[0].privateKeyFile = '../../key.pem'
    $fixture | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $fixturePath
    Assert-Rejected { & $validator -Path $fixturePath -AllowIncomplete }
} finally {
    if (Test-Path -LiteralPath $fixturePath) { Remove-Item -LiteralPath $fixturePath }
}
Write-Output 'Passed: valid example; incomplete deployment, duplicate target, host oversubscription, and key path traversal rejected.'
