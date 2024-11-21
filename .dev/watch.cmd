@echo off
setlocal EnableDelayedExpansion

rem Get the directory of the batch file
set "SCRIPT_DIR=%~dp0"

rem Set default command to build-exec.cmd
set "COMMAND=build-exec.cmd"

rem Check if --spec flag is provided
set "SPEC_FLAG="
for %%i in (%*) do (
    if /i "%%i"=="--spec" set "SPEC_FLAG=true"
)

rem If --spec flag is provided, set command to build-spec.cmd
if defined SPEC_FLAG (
    set "COMMAND=build-spec.cmd"
    rem Remove --spec flag from command arguments
    set "ARGS=%*"
    set "ARGS=!ARGS:--spec=!"
)

rem Run the specified command with the remaining arguments
watchexec -r -e cr -- "%SCRIPT_DIR%%COMMAND%" !ARGS!
rem 
rem 
rem @echo off
rem 
rem rem Get the directory of the batch file
rem set "SCRIPT_DIR=%~dp0"
rem 
rem rem Print the current directory for debugging purposes
rem rem echo Current directory is: %SCRIPT_DIR%
rem 
rem cd /d %~dp0..
rem rem Print the current directory for debugging purposes
rem rem echo Current directory is: 
rem rem cd
rem rem Run watchexec with the specified options
rem watchexec -r -e cr -- "%SCRIPT_DIR%\build-exec.cmd %*"
