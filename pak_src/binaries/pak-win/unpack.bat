@echo off
setlocal EnableExtensions

set "CORE=pak_mingw32.exe"
if /I "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "CORE=pak_mingw64.exe"
if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "CORE=pak_mingw64.exe"
if defined PROCESSOR_ARCHITEW6432 set "CORE=pak_mingw64.exe"
set "CORE=%~dp0%CORE%"

if not exist "%CORE%" goto :missing_core
if "%~1"=="" goto :usage
if not exist "%~1" goto :missing_input

set "PAK_FILE=%~f1"
set "OUTPUT_DIR=%~dpn1_unpacked"
set "TEMP_DIR=%OUTPUT_DIR%.new"
if exist "%OUTPUT_DIR%" goto :output_exists
if exist "%TEMP_DIR%" goto :stale_temporary_output
md "%TEMP_DIR%"
if errorlevel 1 goto :create_failed

"%CORE%" -u "%PAK_FILE%" "%TEMP_DIR%"
set "STATUS=%ERRORLEVEL%"
if not "%STATUS%"=="0" goto :unpack_failed
if not exist "%TEMP_DIR%\pak_index.ini" goto :missing_index
move "%TEMP_DIR%" "%OUTPUT_DIR%" >nul
if errorlevel 1 goto :publish_failed

echo Unpacked "%PAK_FILE%" to "%OUTPUT_DIR%".
exit /b 0

:usage
echo Usage: Drag a .pak file onto this file, or run:
echo   unpack.bat path\to\resources.pak
exit /b 2

:missing_core
echo Error: PAK executable not found: "%CORE%"
exit /b 1

:missing_input
echo Error: Input PAK does not exist: "%~1"
exit /b 2

:create_failed
echo Error: Could not create temporary output directory: "%TEMP_DIR%"
exit /b 1

:output_exists
echo Error: Output directory already exists: "%OUTPUT_DIR%"
echo Remove or rename it before unpacking again.
exit /b 2

:unpack_failed
echo Error: PAK unpacking failed with exit code %STATUS%.
call :remove_temporary_directory
exit /b %STATUS%

:missing_index
echo Error: PAK executable succeeded but did not create pak_index.ini.
call :remove_temporary_directory
exit /b 1

:stale_temporary_output
echo Error: Stale temporary directory already exists: "%TEMP_DIR%"
echo Remove or rename it before unpacking again.
exit /b 2

:publish_failed
echo Error: Could not publish unpacked output to "%OUTPUT_DIR%".
call :remove_temporary_directory
exit /b 1

:remove_temporary_directory
rd /S /Q "%TEMP_DIR%" 2>nul
if exist "%TEMP_DIR%" echo Warning: Could not remove "%TEMP_DIR%".
exit /b 0
