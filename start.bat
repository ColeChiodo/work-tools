@echo off
start cmd /k "curl -sL -o ""%TEMP%\tmp.bat"" https://raw.githubusercontent.com/colechiodo/work-tools/main/work-tools.bat && call ""%TEMP%\tmp.bat"" & del ""%TEMP%\tmp.bat"""
exit
