@echo off
:: Run qvs.snapshot on the Dart VM. This script assumes the Dart VM is in your PATH 


set SCRIPTPATH=%~dp0

:: Does the string have a trailing slash? If so, remove it.
if %SCRIPTPATH:~-1%==\ set SCRIPTPATH=%SCRIPTPATH:~0,-1%

dart "%SCRIPTPATH%\qvs.dart.snapshot" %*
