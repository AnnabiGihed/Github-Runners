#requires -Version 7.4
[CmdletBinding()]
param([switch]$SmokeTest,[string]$ScreenshotPath)
$ErrorActionPreference='Stop'
if (-not $IsWindows) { throw 'This desktop app requires Windows.' }
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') { throw 'Launch with pwsh -STA -File scripts/desktop/Start-RunnerDesktop.ps1' }
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $PSScriptRoot 'RunnerDesktop.psm1') -Force
Import-Module (Join-Path $root 'scripts/controller/RunnerDiagnostics.psm1') -Force
$reader=[Xml.XmlReader]::Create((Join-Path $root 'infra/desktop/MainWindow.xaml'))
try { $window=[Windows.Markup.XamlReader]::Load($reader) } finally { $reader.Dispose() }
$ui=@{}
foreach ($name in @('Tabs','TargetList','NewTarget','ReloadTargets','RemoveTarget','Capacity','OpenGuide','OpenGitHub','TargetId','Owner','AppId','RoutingLabel','Scope','Repository','InstallationId','Slots','BrowseKey','KeyPath','TrustPublic','SaveTarget','SetupTarget','ApplyConfig','CopyLabels','RefreshStatus','RefreshPool','StatusText','CheckHost','CleanDisk','BuildImage','InstallService','StartService','StopService','RestartService','Activity','Output')) {
    $ui[$name]=$window.FindName($name)
    if ($null -eq $ui[$name]) { throw "Missing UI control: $name" }
}
$script:operation=$null
$buttons=@('RemoveTarget','SaveTarget','SetupTarget','ApplyConfig','RefreshStatus','RefreshPool','CheckHost','CleanDisk','BuildImage','InstallService','StartService','StopService','RestartService','NewTarget','ReloadTargets')
function Reload-Targets {
    $config=Get-DesktopTargets
    $ui.TargetList.ItemsSource=@($config.targets)
    $total=[int](($config.targets | Measure-Object maxRunners -Sum).Sum)
    $ui.Capacity.Text="Capacity: $total / $($config.hostMaxRunners) jobs allocated."
}
function Reset-Form {
    foreach ($name in @('TargetId','Owner','Repository','AppId','InstallationId','RoutingLabel','KeyPath')) { $ui[$name].Text='' }
    $ui.TargetId.IsReadOnly=$false;$ui.Owner.IsReadOnly=$false;$ui.Repository.IsReadOnly=$false;$ui.Scope.IsEnabled=$true
    $ui.Slots.Text='1';$ui.Scope.SelectedIndex=0;$ui.TrustPublic.IsChecked=$false
}
function Get-FormRequest {
    $app=0L;$installation=0L;$slots=0
    if (-not [long]::TryParse($ui.AppId.Text,[ref]$app) -or $app -lt 1 -or -not [long]::TryParse($ui.InstallationId.Text,[ref]$installation) -or $installation -lt 1 -or -not [int]::TryParse($ui.Slots.Text,[ref]$slots) -or $slots -lt 1) { throw 'App ID, installation ID and concurrent jobs must be positive integers.' }
    return @{id=$ui.TargetId.Text.Trim();owner=$ui.Owner.Text.Trim();repository=$ui.Repository.Text.Trim();scope=$ui.Scope.SelectedItem.Content;appId=$app;installationId=$installation;maxRunners=$slots;labels=@($ui.RoutingLabel.Text.Split(',',[StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object Trim);keySource=$ui.KeyPath.Text;trustedPublicWorkflows=($ui.TrustPublic.IsChecked -eq $true)}
}
function Start-Action {
    param([string]$Action,$Request=$null)
    if ($script:operation) { return }
    try {
        $psi=[Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
        $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.WorkingDirectory=$root
        $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$psi.RedirectStandardInput=$true
        foreach ($arg in @('-NoLogo','-NoProfile','-NonInteractive','-File',(Join-Path $PSScriptRoot 'Invoke-DesktopAction.ps1'),'-Action',$Action)) { $psi.ArgumentList.Add($arg) }
        $process=[Diagnostics.Process]::Start($psi)
        $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
        if ($null -ne $Request) { $process.StandardInput.Write(($Request | ConvertTo-Json -Depth 12 -Compress)) }
        $process.StandardInput.Close()
        $script:operation=@{Process=$process;Out=$stdout;Err=$stderr;Action=$Action;Started=[DateTimeOffset]::UtcNow}
        foreach ($name in $buttons) { $ui[$name].IsEnabled=$false }
        $ui.Activity.Text="$Action running…";$ui.Output.Text='Working. Long builds and graceful drains can take several minutes.'
    } catch { $ui.Output.Text=Protect-RunnerDiagnosticText -Text $_.Exception.Message;$ui.Activity.Text='Action could not start' }
}
function Invoke-FormAction {
    param([string]$Action)
    try { Start-Action -Action $Action -Request (Get-FormRequest) }
    catch { $ui.Output.Text=Protect-RunnerDiagnosticText -Text $_.Exception.Message }
}
$ui.NewTarget.Add_Click({ $ui.TargetList.SelectedItem=$null;Reset-Form })
$ui.ReloadTargets.Add_Click({ Reload-Targets })
$ui.TargetList.Add_SelectionChanged({
    $target=$ui.TargetList.SelectedItem
    if ($null -eq $target) { return }
    foreach ($name in @('TargetId','Owner','Repository','AppId','InstallationId')) {
        $field=@{TargetId='id';Owner='owner';Repository='repository';AppId='appId';InstallationId='installationId'}[$name]
        $ui[$name].Text=[string]$target.$field
    }
    $ui.RoutingLabel.Text=$target.labels -join ',';$ui.Slots.Text=[string]$target.maxRunners;$ui.KeyPath.Text=''
    $ui.Scope.SelectedIndex=if ($target.scope -eq 'organization') { 1 } else { 0 }
    $ui.TrustPublic.IsChecked=($target.PSObject.Properties.Name -contains 'trustedPublicWorkflows' -and $target.trustedPublicWorkflows)
    $ui.TargetId.IsReadOnly=$true;$ui.Owner.IsReadOnly=$true;$ui.Repository.IsReadOnly=$true;$ui.Scope.IsEnabled=$false
})
$ui.Scope.Add_SelectionChanged({ $ui.Repository.IsEnabled=($ui.Scope.SelectedIndex -eq 0);$ui.TrustPublic.IsEnabled=($ui.Scope.SelectedIndex -eq 0) })
$ui.BrowseKey.Add_Click({ $dialog=[Microsoft.Win32.OpenFileDialog]::new();$dialog.Filter='GitHub App private key (*.pem)|*.pem';if ($dialog.ShowDialog($window)) { $ui.KeyPath.Text=$dialog.FileName } })
$ui.SaveTarget.Add_Click({ Invoke-FormAction 'Save' })
$ui.SetupTarget.Add_Click({ Invoke-FormAction 'Setup' })
$ui.CopyLabels.Add_Click({
    $labels=@($ui.RoutingLabel.Text.Split(',',[StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object Trim)
    if (-not $labels.Count -or @($labels | Where-Object { $_ -notmatch '^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$' }).Count) { $ui.Output.Text='Enter valid routing labels before copying.';return }
    [Windows.Clipboard]::SetText(('runs-on: [self-hosted, linux, '+($labels -join ', ')+']'))
    $ui.Activity.Text='Workflow labels copied. Add them to the intended GitHub workflow jobs.'
})
$ui.RemoveTarget.Add_Click({
    if ($null -eq $ui.TargetList.SelectedItem) { return }
    if ([Windows.MessageBox]::Show($window,'Remove this target from configuration? All runners must first be stopped and drained. Its private key will be retained.','Remove target','YesNo','Question') -eq 'Yes') { Start-Action -Action Remove -Request @{id=$ui.TargetList.SelectedItem.id} }
})
foreach ($pair in @(@('RefreshStatus','Status'),@('RefreshPool','Pool'),@('CheckHost','Host'),@('CleanDisk','Disk'),@('BuildImage','Build'),@('InstallService','Install'),@('StartService','Start'),@('StopService','Stop'),@('RestartService','Apply'),@('ApplyConfig','Apply'))) {
    $action=$pair[1]
    $ui[$pair[0]].Add_Click({ Start-Action -Action $action }.GetNewClosure())
}
$ui.OpenGuide.Add_Click({ Start-Process -FilePath (Join-Path $root 'docs/runbooks/09-desktop-app.md') })
$ui.OpenGitHub.Add_Click({ Start-Process 'https://github.com/settings/apps' })
$timer=[Windows.Threading.DispatcherTimer]::new();$timer.Interval=[TimeSpan]::FromMilliseconds(500)
$timer.Add_Tick({
    if (-not $script:operation) { return }
    $op=$script:operation
    if (-not $op.Process.HasExited -or -not $op.Out.IsCompleted -or -not $op.Err.IsCompleted) {
        $ui.Activity.Text="$($op.Action) running · $([int]([DateTimeOffset]::UtcNow-$op.Started).TotalSeconds)s";return
    }
    $text=Protect-RunnerDiagnosticText -Text ($op.Out.Result+"`n"+$op.Err.Result)
    $ui.Output.Text=$text.Trim();$ui.Output.ScrollToEnd()
    $ui.Activity.Text=if ($op.Process.ExitCode -eq 0) { "$($op.Action) completed" } else { "$($op.Action) failed — review the message below" }
    if ($op.Action -in @('Status','Pool','Host')) { $ui.StatusText.Text=$text.Trim() }
    $op.Process.Dispose();$script:operation=$null
    foreach ($name in $buttons) { $ui[$name].IsEnabled=$true }
    Reload-Targets
})
$window.Add_Closing({ param($sender,$eventArgs)
    if ($script:operation) { $eventArgs.Cancel=$true;$ui.Activity.Text='Wait for the current operation before closing. Jobs continue independently.' }
})
Reload-Targets
if ($SmokeTest) {
    # Exercise the real dispatcher and read-only worker, render without changing target/service state.
    $window.Add_ContentRendered({ $ui.RefreshStatus.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent)) })
    $smoke=[Windows.Threading.DispatcherTimer]::new();$smoke.Interval=[TimeSpan]::FromSeconds(1)
    $script:smokeTicks=0
    $smoke.Add_Tick({
        $script:smokeTicks++
        if ($script:smokeTicks -ge 2 -and -not $script:operation) {
            if ($ScreenshotPath) {
                $window.UpdateLayout()
                $bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new([int]$window.ActualWidth,[int]$window.ActualHeight,96,96,[Windows.Media.PixelFormats]::Pbgra32)
                $bitmap.Render($window);$encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
                $stream=[IO.File]::Create($ScreenshotPath);try { $encoder.Save($stream) } finally { $stream.Dispose() }
            }
            $smoke.Stop();$window.Close()
        }
    });$smoke.Start()
}
$timer.Start()
try { $null=$window.ShowDialog() } finally { $timer.Stop() }
if ($SmokeTest) { if ($ui.Activity.Text -notmatch '^Status completed') { throw 'Desktop worker smoke test failed.' }; 'Desktop loaded, rendered and completed the read-only status worker.' }
