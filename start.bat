@echo off

set "TEMP_BAT=%TEMP%\work-tools.bat"

curl -sL https://raw.githubusercontent.com/YOURNAME/YOURREPO/main/work-tools.bat -o "%TEMP_BAT%"

if not exist "%TEMP_BAT%" (
    echo Failed to download Work Tools.
    exit /b 1
)

conhost.exe cmd.exe /k "%TEMP_BAT%"

del "%TEMP_BAT%"
exit
