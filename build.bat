@echo off
setlocal
echo ========================================================
echo Building Air Defender Radar PBO...
echo ========================================================

set FILEBANK="C:\Program Files (x86)\Steam\steamapps\common\Arma 3 Tools\FileBank\FileBank.exe"

if exist %FILEBANK% (
    echo [INFO] Using official Bohemia FileBank.exe...
    %FILEBANK% -property prefix=arma_radar -dst "@AirDefender_Radar\addons" "Source\arma_radar"
) else (
    echo [INFO] FileBank not found, using Python packer...
    py pack_pbo.py
)

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================================
    echo SUCCESS: @AirDefender_Radar\addons\arma_radar.pbo is ready!
    echo ========================================================
) else (
    echo.
    echo ERROR: Build failed.
)
pause
