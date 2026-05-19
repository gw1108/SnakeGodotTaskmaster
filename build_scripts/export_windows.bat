@echo off
setlocal

REM Exports the Godot project to a Windows standalone build and zips it.
REM Requires:
REM   - Godot 4.6 on PATH
REM   - Windows export templates installed (Editor > Manage Export Templates)

set PROJECT_DIR=%~dp0..\snaketaskmaster
set BUILD_DIR=%PROJECT_DIR%\build\windows
set PRESET=Windows Desktop
set EXE_NAME=snake.exe

echo === Godot Windows Export ===
where godot >nul 2>nul
if errorlevel 1 (
    echo ERROR: 'godot' not found on PATH.
    exit /b 1
)

if not exist "%PROJECT_DIR%\export_presets.cfg" (
    echo ERROR: export_presets.cfg not found in %PROJECT_DIR%
    exit /b 1
)

REM Read config/version from project.godot (format: config/version="1.2.3")
set VERSION=
for /f "tokens=2 delims==" %%V in ('findstr /b "config/version=" "%PROJECT_DIR%\project.godot"') do set VERSION=%%~V
if not defined VERSION (
    echo ERROR: config/version not found in project.godot
    exit /b 1
)
set ZIP_PATH=%PROJECT_DIR%\build\snake-windows-v%VERSION%.zip
echo Version: %VERSION%

if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%" || exit /b 1

echo Exporting "%PRESET%" preset...
pushd "%PROJECT_DIR%"
godot --headless --export-release "%PRESET%" "%BUILD_DIR%\%EXE_NAME%"
set EXPORT_ERR=%ERRORLEVEL%
popd

if not %EXPORT_ERR%==0 (
    echo.
    echo ERROR: Godot export failed with code %EXPORT_ERR%.
    echo If the message mentions missing export templates, open Godot and run:
    echo   Editor ^> Manage Export Templates ^> Download and Install
    exit /b %EXPORT_ERR%
)

if not exist "%BUILD_DIR%\%EXE_NAME%" (
    echo ERROR: Export reported success but %EXE_NAME% is missing.
    exit /b 1
)

echo.
echo Packaging itch.io zip...
if exist "%ZIP_PATH%" del /q "%ZIP_PATH%"
powershell -NoProfile -Command "Compress-Archive -Path '%BUILD_DIR%\*' -DestinationPath '%ZIP_PATH%' -Force" || exit /b 1

echo.
echo === Done ===
echo Windows build: %BUILD_DIR%
echo itch.io zip:   %ZIP_PATH%
echo.
echo Upload the zip to itch.io and tick 'Windows' under platforms.

endlocal
