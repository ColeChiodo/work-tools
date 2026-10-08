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
echo 3. Fix Epic Bluescreen
echo 4. Kill TSManager
echo 5. Count Upgraded PCs
echo 0. Exit
echo.

set /p "choice=Select: "

if "%choice%"=="1" goto :SCREENSAVER
if "%choice%"=="2" goto :SOFTCNTR
if "%choice%"=="3" goto :ENABLEMPR
if "%choice%"=="4" goto :KILLTSMANAGER
if "%choice%"=="5" goto :COUNTUPGRADES
if "%choice%"=="0" goto :END

echo Invalid choice. Try Again.
pause
goto :MENU

:SCREENSAVER
set /p "COMPANY_NAME=Enter company name: "
set "PHOTO_PATH=C:\Program Files (x86)\%COMPANY_NAME%\Screensaver"

echo.
echo Checking screen saver folder...

if not exist "%PHOTO_PATH%\" goto :PATHERROR

echo Folder exists.
goto :CONFIGURE

:PATHERROR
echo.
echo ERROR: Screen saver folder not found.
echo %PHOTO_PATH%
pause
goto :MENU

:CONFIGURE
echo Configuring screen saver...

reg add "HKCU\Control Panel\Desktop" /v "SCRNSAVE.EXE" /t REG_SZ /d "%SystemRoot%\System32\PhotoScreensaver.scr" /f
reg add "HKCU\Control Panel\Desktop" /v "ScreenSaveActive" /t REG_SZ /d "1" /f
reg add "HKCU\Control Panel\Desktop" /v "ScreenSaveTimeOut" /t REG_SZ /d "600" /f
reg add "HKCU\Control Panel\Desktop" /v "ScreenSaverIsSecure" /t REG_SZ /d "1" /f

reg add "HKCU\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" /v "ImagesRootPath" /t REG_SZ /d "%PHOTO_PATH%" /f
reg add "HKCU\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" /v "Shuffle" /t REG_DWORD /d "1" /f
reg add "HKCU\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" /v "Speed" /t REG_DWORD /d "0" /f

echo.
echo Screen saver configured.

pause
goto :MENU

:SOFTCNTR
echo Stopping core deployment services...

net stop wuauserv
net stop bits
net stop cryptsvc

echo.
echo Clearing update cache files...

rd /s /q "%windir%\SoftwareDistribution\DataStore"

echo.
echo Stopping stuck task...

powershell -NoProfile -Command "Get-CimInstance -Namespace root\ccm\SoftMgmtAgent -ClassName CCM_TSExecutionRequest | Remove-CimInstance"

echo.
echo Refreshing Software Center...

powershell -NoProfile -Command "Restart-Service ccmexec -Force"

echo.
echo Done.
echo.

pause
goto :MENU

:ENABLEMPR
echo Fixing EPIC Login bluescreen...

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableMprNotification" /t REG_DWORD /d 1 /f

gpupdate /force

echo.
echo MPR Enabled.

pause
goto :MENU

:KILLTSMANAGER
set /p "PCName=Enter PC name: "

echo.
echo Checking %PCName%...
echo.

tasklist /s %PCName% /fi "IMAGENAME eq TsManager.exe" | findstr /i "TsManager.exe" >nul

if %ERRORLEVEL% EQU 0 (
    echo TsManager.exe found on %PCName%.
    echo Killing process...

    taskkill /s %PCName% /im TsManager.exe /f

    if %ERRORLEVEL% EQU 0 (
        echo.
        echo TsManager.exe successfully terminated.
    ) else (
        echo.
        echo Failed to terminate TsManager.exe.
    )
) else (
    echo TsManager.exe was not found on %PCName%.
)

echo.
echo Done.

pause
goto :MENU

:COUNTUPGRADES
echo Counting PCs upgraded to Windows 11...
echo.

set /a count=0
set /a total=0

for /f "delims=" %%A in ('powershell -NoProfile -Command "Get-ADComputer -Filter * -Properties OperatingSystem | Measure-Object | Select-Object -ExpandProperty Count"') do (
    set "total=%%A"
)

for /f "delims=" %%A in ('powershell -NoProfile -Command "Get-ADComputer -Filter * -Properties OperatingSystem | Where-Object { $_.OperatingSystem -like 'Windows 11*' } | Measure-Object | Select-Object -ExpandProperty Count"') do (
    set "count=%%A"
)

if "%total%"=="0" (
    echo No computers were found.
    echo.
    pause
    goto :MENU
)

set /a percentage=count*100/total

echo Windows 11 computers: %count% / %total%
echo Windows 11 percentage: %percentage%%%
echo.

pause
goto :MENU

:END
echo Goodbye :)
pause

endlocal
exit /b
