@echo off
set /p USER_ID="Enter Roblox User ID (e.g. Creator ID): "
python -I tools\art\upload_assets.py --user %USER_ID% --only ui/icons/trade_license
echo.
echo If Studio is open, resolving decals now...
node tools\ui\resolve_decals.mjs
pause
