import { execFile } from "node:child_process";
import { promisify } from "node:util";

type DialogKind = "open" | "save" | "texture";

const runFile = promisify(execFile);
const picker = `
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
if ($env:AURA_VFX_PICK_KIND -eq 'save') {
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Title = 'Save particle project'
    $dialog.DefaultExt = 'json'
    $dialog.OverwritePrompt = $true
} else {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.CheckFileExists = $true
    $dialog.Title = 'Open particle project'
}
$dialog.Filter = 'Particle projects (*.json)|*.json'
if ($env:AURA_VFX_PICK_KIND -eq 'texture') {
    $dialog.Title = 'Import texture'
    $dialog.Filter = 'Textures (*.png;*.jpg;*.jpeg;*.webp;*.gif)|*.png;*.jpg;*.jpeg;*.webp;*.gif'
}
$dialog.InitialDirectory = $env:AURA_VFX_PICK_DIR
$dialog.FileName = $env:AURA_VFX_PICK_NAME
$owner = New-Object System.Windows.Forms.Form
$owner.ShowInTaskbar = $false
$owner.TopMost = $true
$owner.Opacity = 0
try {
    $owner.Show()
    if ($dialog.ShowDialog($owner) -eq 'OK') { [Console]::Write($dialog.FileName) }
} finally {
    $dialog.Dispose()
    $owner.Dispose()
}
`;

export async function pickFile(kind: DialogKind, directory: string, name = ""): Promise<string | null> {
  if (process.platform !== "win32") throw new Error("Enter a file path to use the editor on this platform.");
  const { stdout } = await runFile("powershell.exe", ["-NoProfile", "-NonInteractive", "-STA", "-Command", picker], {
    windowsHide: true,
    encoding: "utf8",
    env: {
      ...process.env,
      AURA_VFX_PICK_KIND: kind,
      AURA_VFX_PICK_DIR: directory,
      AURA_VFX_PICK_NAME: name,
    },
  });
  return stdout.trim() || null;
}
