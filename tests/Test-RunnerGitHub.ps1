#requires -Version 7.2
$ErrorActionPreference='Stop'
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/github/RunnerGitHub.psm1') -Force
$rsa=[Security.Cryptography.RSA]::Create(2048)
function Decode-Base64Url([string]$Text) {
    $padded=$Text.Replace('-','+').Replace('_','/')
    $padded+='=' * ((4-$padded.Length%4)%4)
    return ,([Convert]::FromBase64String($padded))
}
try {
    $jwt=New-RunnerAppJwt -AppId 123 -PrivateKeyPem $rsa.ExportRSAPrivateKeyPem()
    $parts=$jwt.Split('.')
    $claims=[Text.Encoding]::UTF8.GetString((Decode-Base64Url $parts[1])) | ConvertFrom-Json
    if ($claims.iss -ne '123' -or $claims.exp-$claims.iat -ne 600) { throw 'Invalid JWT claims.' }
    if (-not $rsa.VerifyData([Text.Encoding]::UTF8.GetBytes("$($parts[0]).$($parts[1])"),(Decode-Base64Url $parts[2]),[Security.Cryptography.HashAlgorithmName]::SHA256,[Security.Cryptography.RSASignaturePadding]::Pkcs1)) { throw 'Invalid RSA signature.' }
    if ($rsa.VerifyData([Text.Encoding]::UTF8.GetBytes('tampered'),(Decode-Base64Url $parts[2]),[Security.Cryptography.HashAlgorithmName]::SHA256,[Security.Cryptography.RSASignaturePadding]::Pkcs1)) { throw 'Tampering accepted.' }
} finally { $rsa.Dispose(); $jwt=$null }
$target=[pscustomobject]@{appId=1;installationId=2;owner='example';scope='organization'}
$installation=[pscustomobject]@{app_id=1;id=2;account=[pscustomobject]@{login='example';type='Organization'};suspended_at=$null;permissions=[pscustomobject]@{organization_self_hosted_runners='write'}}
Assert-RunnerInstallation -Target $target -Installation $installation
$target | Add-Member -NotePropertyName scalingMode -NotePropertyValue demand
$rejected=$false
try { Assert-RunnerInstallation -Target $target -Installation $installation } catch { $rejected=$true }
if (-not $rejected) { throw 'Demand mode accepted an installation without Actions read.' }
$installation.permissions | Add-Member -NotePropertyName actions -NotePropertyValue read
Assert-RunnerInstallation -Target $target -Installation $installation
foreach ($case in @('owner','permission','suspended','app')) {
    $copy=$installation | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    switch ($case) {
        owner {$copy.account.login='wrong'}
        permission {$copy.permissions.organization_self_hosted_runners='read'}
        suspended {$copy.suspended_at='2026-10-08'}
        app {$copy.app_id=3}
    }
    $rejected=$false
    try { Assert-RunnerInstallation -Target $target -Installation $copy } catch { $rejected=$true }
    if (-not $rejected) { throw "Installation mismatch accepted: $case" }
}
Write-Output 'PASS: JWT signature, claims, tampering rejection, and owner/permission/suspension/App mismatch rejection. No network or real credentials used.'
