#requires -Version 7.2
Set-StrictMode -Version Latest

function ConvertTo-Base64Url {
    param([byte[]]$Bytes)
    [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+','-').Replace('/','_')
}

function New-RunnerAppJwt {
    param([Parameter(Mandatory)][long]$AppId, [Parameter(Mandatory)][string]$PrivateKeyPem)
    if ($AppId -lt 1) { throw 'Invalid App ID.' }
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $header = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes('{"alg":"RS256","typ":"JWT"}'))
    $claims = @{iat=$now-60;exp=$now+540;iss=[string]$AppId} | ConvertTo-Json -Compress
    $payload = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($claims))
    $rsa = [Security.Cryptography.RSA]::Create()
    try {
        $rsa.ImportFromPem($PrivateKeyPem)
        $signature = $rsa.SignData([Text.Encoding]::UTF8.GetBytes("$header.$payload"), [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
        return "$header.$payload.$(ConvertTo-Base64Url $signature)"
    } catch { throw 'App key import/signing failed; check local PEM format.' }
    finally { $rsa.Dispose(); $PrivateKeyPem=$null }
}

function Invoke-RunnerGitHubApi {
    param(
        [Parameter(Mandatory)][ValidateSet('GET','POST','DELETE')][string]$Method,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Token,
        [hashtable]$Body
    )
    if ($Path -notmatch '^/[A-Za-z0-9_./?=&%-]+$' -or $Path.Contains('..') -or $Path.StartsWith('//')) { throw 'Invalid GitHub API path.' }
    $request = @{
        Uri="https://api.github.com$Path";Method=$Method;TimeoutSec=30;MaximumRedirection=0
        Headers=@{Accept='application/vnd.github+json';Authorization="Bearer $Token";'X-GitHub-Api-Version'='2026-03-10';'User-Agent'='ephemeral-runner-provisioner'}
        ErrorAction='Stop';Verbose=$false;Debug=$false
    }
    if ($Body) { $request.Body=$Body | ConvertTo-Json -Depth 10 -Compress; $request.ContentType='application/json' }
    try { Invoke-RestMethod @request }
    catch {
        $responseProperty = $_.Exception.PSObject.Properties['Response']
        $status = if ($responseProperty -and $responseProperty.Value) { [int]$responseProperty.Value.StatusCode } else { 0 }
        # Never include response bodies, headers, tokens, or underlying exception details.
        $meaning = switch ($status) {
            401 {'authentication rejected'}
            403 {'permission denied or rate limited'}
            404 {'resource unavailable or installation/target mismatch'}
            429 {'rate limited'}
            0 {'transport failure or timeout'}
            default {'request failed'}
        }
        throw "GitHub API HTTP ${status}: $meaning. No automatic mutation retry performed."
    } finally { $Token=$null; $request=$null }
}

function Assert-RunnerInstallation {
    param([Parameter(Mandatory)]$Target, [Parameter(Mandatory)]$Installation)
    if ($Installation.app_id -ne $Target.appId -or $Installation.id -ne $Target.installationId) { throw 'App/installation ID mismatch.' }
    if ($Installation.account.login -ine $Target.owner) { throw 'Installation owner mismatch.' }
    if ($Installation.suspended_at) { throw 'App installation is suspended.' }
    $permission = if ($Target.scope -eq 'repository') { 'administration' } else { 'organization_self_hosted_runners' }
    if (-not $Installation.permissions.PSObject.Properties[$permission] -or $Installation.permissions.$permission -ne 'write') { throw 'Required runner management permission is missing.' }
    if ($Target.PSObject.Properties['scalingMode'] -and $Target.scalingMode -eq 'demand' -and (-not $Installation.permissions.PSObject.Properties['actions'] -or $Installation.permissions.actions -notin @('read','write'))) { throw 'Demand scaling requires approved GitHub App repository Actions read permission.' }
    if ($Target.scope -eq 'organization' -and $Installation.account.type -ne 'Organization') { throw 'Organization target is not an organization installation.' }
}

function Get-RunnerInstallationToken {
    param([Parameter(Mandatory)]$Target, [Parameter(Mandatory)][string]$RepositoryRoot)
    if ($Target.privateKeyFile -notmatch '^\.local/secrets/[a-zA-Z0-9_-]+\.pem$') { throw 'Unsafe private-key reference.' }
    $keyPath = Join-Path $RepositoryRoot $Target.privateKeyFile
    if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) { throw 'Required local App private key is missing.' }
    $jwt = New-RunnerAppJwt -AppId $Target.appId -PrivateKeyPem (Get-Content -LiteralPath $keyPath -Raw)
    try {
        $installation = Invoke-RunnerGitHubApi -Method GET -Path "/app/installations/$($Target.installationId)" -Token $jwt
        Assert-RunnerInstallation -Target $Target -Installation $installation
        $permissions = if ($Target.scope -eq 'repository') { @{administration='write'} } else { @{organization_self_hosted_runners='write'} }
        if ($Target.PSObject.Properties['scalingMode'] -and $Target.scalingMode -eq 'demand') { $permissions.actions='read' }
        $body = @{permissions=$permissions}
        if ($Target.scope -eq 'repository') { $body.repositories=@($Target.repository) }
        # Caller must assign the result; never display it or persist it.
        Invoke-RunnerGitHubApi -Method POST -Path "/app/installations/$($Target.installationId)/access_tokens" -Token $jwt -Body $body
    } finally { $jwt=$null }
}

Export-ModuleMember -Function New-RunnerAppJwt,Invoke-RunnerGitHubApi,Assert-RunnerInstallation,Get-RunnerInstallationToken
