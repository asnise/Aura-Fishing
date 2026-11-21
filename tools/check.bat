@echo off
REM One-command QA: rojo sourcemap + luau-lsp analyze + banned characters. See tools\check.mjs
cd /d "%~dp0.."
node tools\check.mjs
