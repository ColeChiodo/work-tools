@echo off

curl -sL https://raw.githubusercontent.com/colechiodo/work-tools/main/work-tools.bat -o "%TEMP%\work-tools.bat"
call "%TEMP%\work-tools.bat"
del "%TEMP%\work-tools.bat"
