@echo off
REM Build a standalone place file you can open directly in Studio
cd /d "%~dp0.."
"D:\tools\rojo\rojo.exe" build default.project.json -o build\AuraFishing.rbxlx
