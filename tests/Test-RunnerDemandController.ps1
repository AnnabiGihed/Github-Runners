#requires -Version 7.4
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$fixture=Join-Path $root ('.local/tests/demand-controller-'+[guid]::NewGuid().ToString('N'))
try {
    foreach ($directory in @('scripts/controller','scripts/github','scripts/config','scripts/host','config','.local/controller')) { New-Item (Join-Path $fixture $directory) -ItemType Directory -Force | Out-Null }
    foreach ($file in @('scripts/controller/RunnerDemand.psm1','scripts/controller/RunnerDiagnostics.psm1','scripts/config/Test-RunnerConfiguration.ps1','scripts/config/Test-RunnerResources.ps1','config/runner-resources.json','config/docker-images.lock.json')) { Copy-Item (Join-Path $root $file) (Join-Path $fixture $file) }
    '{"schemaVersion":1,"hostMaxRunners":4,"targets":[{"id":"fixture","scope":"repository","owner":"Fixture","repository":"Repo","appId":1,"installationId":2,"privateKeyFile":".local/secrets/fixture.pem","labels":["fixture"],"maxRunners":4,"scalingMode":"demand"}]}' | Set-Content (Join-Path $fixture '.local/targets.json')
    '''{"CPUs":8,"EngineMemoryGiB":16}''' | Set-Content (Join-Path $fixture 'scripts/host/Test-RunnerHost.ps1')
    @'
function Invoke-RunnerGitHubApi {
    param($Method,$Path,$Token)
    if ($Method -eq 'DELETE') { return }
    $tick=[int](Get-Content (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) '.local/tick'))
    if ($tick -eq 4) { throw 'Fixture queue outage' }
    if ($Path -like '*status=in_progress*') { return [pscustomobject]@{workflow_runs=@()} }
    if ($Path -like '*status=queued*') { return [pscustomobject]@{workflow_runs=@([pscustomobject]@{id=1;run_attempt=1})} }
    $count=if ($tick -eq 2) { 2 } elseif ($tick -eq 3) { 1 } else { 0 }
    [pscustomobject]@{jobs=@(for ($i=0;$i -lt $count;$i++) { [pscustomobject]@{status='queued';labels=@('fixture')} })}
}
Export-ModuleMember Invoke-RunnerGitHubApi
'@ | Set-Content (Join-Path $fixture 'scripts/github/RunnerGitHub.psm1')
    $source=[IO.File]::ReadAllText((Join-Path $root 'scripts/controller/Start-RunnerController.ps1'))
    $tokens=$null;$errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseInput($source,[ref]$tokens,[ref]$errors)
    $replacements=@{
        Api='function Api($target,$method,$suffix) { $tokens[$target.id]=@{token="fixture";expires_at="2099-01-01"};return }'
        'Remote-Runner'=@'
function Remote-Runner($target,$name) {
    $tick=[int](Get-Content (Join-Path $repoRoot '.local/tick'))
    [pscustomobject]@{status='online';busy=($tick -in @(3,4,5) -and $name -eq 'fixture-1')}
}
'@
        'Invoke-ControllerDocker'='function Invoke-ControllerDocker($Arguments) { ''[{"State":{"Running":true}}]'' }'
        Cleanup=@'
function Cleanup($slot) {
    $remote=Remote-Runner $null $slot.name
    if ($remote.busy) { throw 'Busy fixture must not be destroyed.' }
    $state.slots=@($state.slots | Where-Object name -ne $slot.name)
    $state | ConvertTo-Json -Depth 10 | Set-Content $statePath
}
'@
        Provision=@'
function Provision($target) {
    $number=@($state.slots).Count+1
    $state.slots+=@([pscustomobject]@{name="fixture-$number";targetId=$target.id;created=[DateTimeOffset]::UtcNow.AddMinutes(-4).ToString('o');seenOnline=$true})
}
'@
        'Save-State'=@'
function Save-State {
    $tickPath=Join-Path $repoRoot '.local/tick'
    $tick=if (Test-Path $tickPath) { [int](Get-Content $tickPath)+1 } else { 1 }
    $count=@($state.slots).Count
    if ($tick -gt 1) { Add-Content (Join-Path $repoRoot '.local/counts') $count }
    Set-Content $tickPath $tick
    $state | ConvertTo-Json -Depth 10 | Set-Content $statePath
    if ($tick -ge 7) { New-Item (Join-Path $repoRoot '.local/controller/stop') -ItemType File -Force | Out-Null }
}
'@
    }
    $functions=$ast.FindAll({param($node);$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -in $replacements.Keys},$true) | Sort-Object { $_.Extent.StartOffset } -Descending
    foreach ($function in $functions) { $source=$source.Remove($function.Extent.StartOffset,$function.Extent.EndOffset-$function.Extent.StartOffset).Insert($function.Extent.StartOffset,$replacements[$function.Name]) }
    $source=$source.Replace('$runnerImageId=$null',"function docker { `$global:LASTEXITCODE=0; 'sha256:'+('a'*64) }; function Save-RunnerDiagnostics { };`n`$runnerImageId=`$null")
    $source=$source.Replace('.AddSeconds($interval)','.AddSeconds(0)').Replace('Start-Sleep -Seconds 10','Start-Sleep -Milliseconds 1')
    $controller=Join-Path $fixture 'scripts/controller/Start-RunnerController.ps1'
    [IO.File]::WriteAllText($controller,$source)
    Push-Location $fixture
    try { & (Get-Process -Id $PID).Path -NoProfile -File $controller -Continuous -DrainSeconds 0; if ($LASTEXITCODE -ne 0) { throw 'Fixture controller failed.' } } finally { Pop-Location }
    $counts=@(Get-Content (Join-Path $fixture '.local/counts') | ForEach-Object { [int]$_ })
    if (($counts -join ',') -ne '0,2,2,2,1,0') { throw ('Unexpected controller scaling trajectory: '+($counts -join ',')) }
    'Controller demand integration passed: zero -> two queued -> busy+queued -> API failure retains -> busy preserved -> zero. Docker/GitHub effects were isolated substitutes.'
} finally {
    $resolved=[IO.Path]::GetFullPath($fixture)
    $allowed=[IO.Path]::GetFullPath((Join-Path $root '.local/tests'))+[IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture cleanup outside workspace refused.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
