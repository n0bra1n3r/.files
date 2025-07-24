@echo off

rem Bypass "Terminate Batch Job" prompt.
if "%~1"=="-fixed_ctrl_c" (
   rem Remove the -fixed_ctrl_c parameter
   shift
) else (
   rem Run the batch with <null and -fixed_ctrl_c
   call <nul %0 -fixed_ctrl_c %*
   goto :EOF
)

setlocal enabledelayedexpansion

rem Combine all arguments into one launch command
set "LAUNCH_CMD="
:CollectArgs
if not "%~1"=="" (
    set "LAUNCH_CMD=!LAUNCH_CMD! %~1"
    shift
    goto :CollectArgs
)

rem Fallback to run.txt if no args provided
if "!LAUNCH_CMD!"=="" (
    if not exist "run.txt" (
        echo Usage: %~nx0 executable_name.exe [optional arguments]
        echo Or provide full command line in run.txt
        exit /b 1
    )

    for /f "usebackq delims=" %%A in ("run.txt") do (
        set "LAUNCH_CMD=%%A"
        goto :AfterRead
    )
)

:AfterRead
echo Launch command: [%LAUNCH_CMD%]

rem Extract just the executable name (first token)
for %%B in (!LAUNCH_CMD!) do (
    set "EXE_NAME=%%~nxB"
    goto :StartSearch
)

:StartSearch
set "LATEST_TIME=0"
set "LATEST_PATH="

for /d %%D in (*) do (
    if exist "%%~fD\%EXE_NAME%" (
        for %%F in ("%%~fD\%EXE_NAME%") do (
            set "FILE_TIME=%%~tF"
            if "!FILE_TIME!" gtr "!LATEST_TIME!" (
                set "LATEST_TIME=!FILE_TIME!"
                set "LATEST_PATH=%%~fD\%EXE_NAME%"
            )
        )
    )
)

if "!LATEST_PATH!"=="" (
    echo Error: %EXE_NAME% not found in any subdirectory
    exit /b 1
)

"!LATEST_PATH!" !LAUNCH_CMD:%EXE_NAME%=!

