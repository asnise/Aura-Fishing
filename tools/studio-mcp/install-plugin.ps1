# Builds the Studio Bridge plugin with Rojo and installs it into the local Studio Plugins folder.
# Usage: powershell -ExecutionPolicy Bypass -File install-plugin.ps1
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$rojo = if ($env:ROJO) { $env:ROJO } else { "D:\tools\rojo\rojo.exe" }
$pluginsDir = Join-Path $env:LOCALAPPDATA "Roblox\Plugins"
New-Item -ItemType Directory -Force $pluginsDir | Out-Null
$out = Join-Path $pluginsDir "AuraStudioBridge.rbxm"
& $rojo build (Join-Path $here "plugin\default.project.json") -o $out
if ($LASTEXITCODE -ne 0) { throw "rojo build failed" }
Write-Host "Installed $out"
Write-Host "Restart Roblox Studio to load the new version (Studio does not reload plugin files while open)."
