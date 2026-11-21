@echo off
REM Live-sync src/ into Roblox Studio (open Studio > Rojo plugin > Connect)
cd /d "%~dp0.."
"D:\tools\rojo\rojo.exe" serve default.project.json
