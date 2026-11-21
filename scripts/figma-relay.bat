@echo off
REM Local relay between Claude (FigmaRoblox MCP) and the Figma plugin. Keep this window open.
title Figma relay :3055
cd /d "%~dp0..\Figma For Roblox\cursor-talk-to-figma-mcp"

netstat -ano | findstr /R /C:":3055 .*LISTENING" >nul
if %errorlevel%==0 (
  echo A relay is already running on port 3055 - nothing to do.
  echo If it is the old upstream one ^(bunx cursor-talk-to-figma-socket^), close it and run this again.
  netstat -ano | findstr /R /C:":3055 .*LISTENING"
  pause
  exit /b 0
)

bun run src/socket.ts
echo.
echo Relay stopped ^(exit code %errorlevel%^).
pause
