@echo off
set ROOT=%~dp0..
set APP=%1
cd /d %ROOT%
REM build the app and run it with the given arguments
set APPCALL="%ROOT%\bin\%APP%" %*
echo "APP = %APP%"
echo "APPCALL = %APPCALL%"


call shards build %APP% && call "%APPCALL%"
