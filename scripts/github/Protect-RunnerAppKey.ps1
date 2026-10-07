[CmdletBinding()]
param([Parameter(Mandatory)][string]$Path)
$ErrorActionPreference='Stop'
$key=Get-Item -LiteralPath $Path
if ($key.PSIsContainer -or $key.LinkType) { throw 'Expected a regular private-key file.' }
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$acl=[Security.AccessControl.FileSecurity]::new()
$acl.SetOwner($identity.User)
$acl.SetAccessRuleProtection($true,$false)
$rule=[Security.AccessControl.FileSystemAccessRule]::new($identity.User,[Security.AccessControl.FileSystemRights]::FullControl,[Security.AccessControl.AccessControlType]::Allow)
$acl.AddAccessRule($rule)
Set-Acl -LiteralPath $key.FullName -AclObject $acl
$actual=Get-Acl -LiteralPath $key.FullName
if (-not $actual.AreAccessRulesProtected) { throw 'ACL inheritance remains enabled.' }
foreach ($entry in $actual.Access) {
    if ($entry.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value -ne $identity.User.Value) { throw 'Unexpected private-key access rule.' }
}
Write-Output 'Private-key ACL restricted to the current Windows user; contents were not displayed.'
