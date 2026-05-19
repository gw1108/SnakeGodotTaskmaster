@echo off
setlocal

REM Runs every platform export in sequence. Stops on the first failure.

set SCRIPT_DIR=%~dp0

echo === Building Web ===
call "%SCRIPT_DIR%export_web.bat"
if errorlevel 1 (
    echo.
    echo build_all: web export failed, aborting.
    exit /b %ERRORLEVEL%
)

echo.
echo === Building Windows ===
call "%SCRIPT_DIR%export_windows.bat"
if errorlevel 1 (
    echo.
    echo build_all: windows export failed.
    exit /b %ERRORLEVEL%
)

echo.
echo === All builds complete ===

endlocal
