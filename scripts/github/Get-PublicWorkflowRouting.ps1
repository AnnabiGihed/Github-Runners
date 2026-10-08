[CmdletBinding()]
param([string]$ConfigPath='.local/targets.json', [Parameter(Mandatory)][string]$TargetId, [string]$Ref='main', [string[]]$WorkflowNames=@())
$ErrorActionPreference='Stop'
$config=Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$target=@($config.targets | Where-Object id -eq $TargetId)
if ($target.Count -ne 1 -or $target[0].scope -ne 'repository') { throw 'Expected one repository target.' }
$repo="$($target[0].owner)/$($target[0].repository)"
$headers=@{Accept='application/vnd.github+json';'User-Agent'='runner-routing-audit';'X-GitHub-Api-Version'='2026-03-10'}
$encodedRef=[Uri]::EscapeDataString($Ref)
if ($WorkflowNames.Count) {
    foreach ($name in $WorkflowNames) {
        if ($name -notmatch '^[A-Za-z0-9_.-]+\.ya?ml$') { throw 'Invalid workflow filename.' }
        $yaml=Invoke-RestMethod -Uri "https://raw.githubusercontent.com/$repo/$Ref/.github/workflows/$name" -TimeoutSec 30
        [pscustomobject]@{Workflow=$name;Ref=$Ref;Routing=(@([regex]::Matches([string]$yaml,'(?m)^\s*runs-on:\s*(.+)$') | ForEach-Object { $_.Groups[1].Value.Trim() }) -join '; ')}
    }
    return
}
$files=Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/contents/.github/workflows?ref=$encodedRef" -Headers $headers -TimeoutSec 30
foreach ($file in $files | Where-Object name -match '\.ya?ml$') {
    $path=[Uri]::EscapeDataString($file.name)
    $content=Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/contents/.github/workflows/${path}?ref=$encodedRef" -Headers $headers -TimeoutSec 30
    if ($content.encoding -ne 'base64') { throw 'Unsupported contents encoding.' }
    $yaml=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($content.content))
    [pscustomobject]@{Workflow=$file.name;Ref=$Ref;FileSha=$content.sha;Routing=(@([regex]::Matches($yaml,'(?m)^\s*runs-on:\s*(.+)$') | ForEach-Object { $_.Groups[1].Value.Trim() }) -join '; ')}
}
