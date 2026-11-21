@echo off
REM Build the "Aura UI" Studio panel into your local Plugins folder. Restart Studio once afterwards.
cd /d "%~dp0plugin"
"D:\tools\rojo\rojo.exe" build default.project.json -o "%LOCALAPPDATA%\Roblox\Plugins\AuraUIScreens.rbxm"
