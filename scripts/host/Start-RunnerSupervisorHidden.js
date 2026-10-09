// Windows Script Host JScript, launched by wscript.exe (no console window).
// Wait for PowerShell so Task Scheduler tracks the supervisor's full lifetime.
if (WScript.Arguments.length !== 2) { WScript.Quit(2); }
var runtime = WScript.Arguments.Item(0);
var supervisor = WScript.Arguments.Item(1);
var files = new ActiveXObject("Scripting.FileSystemObject");
if (!files.FileExists(runtime) || !files.FileExists(supervisor) ||
    /["%\r\n]/.test(runtime + supervisor)) { WScript.Quit(2); }
var shell = new ActiveXObject("WScript.Shell");
shell.CurrentDirectory = files.GetParentFolderName(files.GetParentFolderName(files.GetParentFolderName(supervisor)));
var command = '"' + runtime + '" -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -File "' + supervisor + '"';
try { WScript.Quit(shell.Run(command, 0, true)); }
catch (error) { WScript.Quit(1); }
