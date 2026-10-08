@echo off
setlocal

for /f "tokens=1,* delims=:" %%A in ('systeminfo ^| findstr /B /C:"OS Name" /C:"System Model"') do (
    for /f "tokens=* delims= " %%C in ("%%B") do (
        if "%%A"=="OS Name" set "OS_NAME=%%C"
        if "%%A"=="System Model" set "SYSTEM_MODEL=%%C"
    )
)

for /f "delims=" %%A in ('hostname') do set "HOSTNAME=%%A"

:MENU
cls
echo ==============================
echo          Work Tools
echo ==============================
echo.
echo Hostname: %HOSTNAME%
echo Model:    %SYSTEM_MODEL%
echo OS:       %OS_NAME%
echo.
echo ==============================
echo.
echo 1. Screen Saver
echo 2. Reset Software Center
echo 3. Kill TSManager
echo 4. Count Upgraded PCs
echo 0. Exit
echo.

set /p choice="Select: "

if "%choice%"=="1" goto SCREENSAVER
if "%choice%"=="2" goto RESETSOFTCNTR
if "%choice%"=="3" goto KILLTSMANAGER
if "%choice%"=="4" goto COUNTUPGRADES
if "%choice%"=="0" goto END

echo Invalid choice. Try Again.
pause
goto MENU

:SCREENSAVER
set /p COMPANY_NAME="Enter company name: "
set "PHOTO_PATH=C:\Program Files (x86)\%COMPANY_NAME%\Screensaver"

echo.
echo Checking screen saver folder...

if not exist "%PHOTO_PATH%\" goto :PathError

echo Folder exists.
goto :Configure

:PathError
echo.
echo ERROR: Screen saver folder not found.
echo %PHOTO_PATH%
pause
goto MENU

:Configure
echo Configuring screen saver...

:: Select Photos screen saver
reg add "HKCU\Control Panel\Desktop" /v "SCRNSAVE.EXE" /t REG_SZ /d "%SystemRoot%\System32\PhotoScreensaver.scr" /f

:: Enable screen saver
reg add "HKCU\Control Panel\Desktop" /v "ScreenSaveActive" /t REG_SZ /d "1" /f

:: 10 minute timeout
reg add "HKCU\Control Panel\Desktop" /v "ScreenSaveTimeOut" /t REG_SZ /d "600" /f

:: Require logon/password on resume
reg add "HKCU\Control Panel\Desktop" /v "ScreenSaverIsSecure" /t REG_SZ /d "1" /f

:: Photos screen saver settings
reg add "HKCU\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" /v "ImagesRootPath" /t REG_SZ /d "%PHOTO_PATH%" /f

:: Shuffle pictures
reg add "HKCU\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" /v "Shuffle" /t REG_DWORD /d "1" /f

:: Slideshow speed
reg add "HKCU\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" /v "Speed" /t REG_DWORD /d "0" /f

echo.
echo Screen saver configured.

pause
goto MENU
 
:RESETSOFTCNTR
:: Forcefully stop core deployment services
echo Stopping core deployment services...
net stop wuauserv
net stop bits
net stop cryptsvc
 
:: Clear the update cache files
echo Clearing update cache files...
rd /s /q %windir%\SoftwareDistribution\DataStore
 
:: Drop stuck task
echo Stopping stuck task...
powershell -Command "Get-CimInstance -Namespace root\ccm\SoftMgmtAgent -ClassName CCM_TSExecutionRequest | Remove-CimInstance"
 
:: refresh software center
echo Refreshing software center...
powershell -Command "Restart-Service ccmexec -Force"
 
echo Done.
echo.
pause
goto MENU

:KILLTSMANAGER
set /p PCName="Enter PC name: "
echo.
echo Checking %PCName%...

tasklist /s %PCName% /fi "IMAGENAME eq TsManager.exe" | findstr /i "TsManager.exe" >nul

if %ERRORLEVEL% EQU 0 (
    echo TsManager.exe found on %PCName%. Killing process...
    taskkill /s %PCName% /im TsManager.exe /f

    if %ERRORLEVEL% EQU 0 (
        echo TsManager.exe successfully terminated.
    ) else (
        echo Failed to terminate TsManager.exe.
    )
) else (
    echo TsManager.exe was not found on %PCName%.
)

echo.
echo Done.
pause
goto MENU

:COUNTUPGRADES
echo Counting PCs upgraded to Windows 11...

set /a count=0
set /a total=0

for /f "delims=" %%A in ('powershell -NoProfile -Command "Get-ADComputer -Filter * -Properties OperatingSystem | Measure-Object | Select-Object -ExpandProperty Count"') do (
    set total=%%A
)

for /f "delims=" %%A in ('powershell -NoProfile -Command "Get-ADComputer -Filter * -Properties OperatingSystem | Where-Object { $_.OperatingSystem -like 'Windows 11*' } | Measure-Object | Select-Object -ExpandProperty Count"') do (
    set count=%%A
)

set /a percentage=count*100/total

echo Windows 11 computers: %count% / %total%
echo Windows 11 percentage: %percentage%%%

pause
goto MENU

:END
echo Goodbye :)
pause
endlocal
exit /b
