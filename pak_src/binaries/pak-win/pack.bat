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

set "INDEX_FILE=%~f1"
set "OUTPUT_FILE=%~dpn1_packed.pak"
set "TEMP_OUTPUT=%OUTPUT_FILE%.new"
if exist "%TEMP_OUTPUT%" del /Q "%TEMP_OUTPUT%"
if exist "%TEMP_OUTPUT%" goto :stale_temporary_output

"%CORE%" -p "%INDEX_FILE%" "%TEMP_OUTPUT%"
set "STATUS=%ERRORLEVEL%"
if not "%STATUS%"=="0" goto :pack_failed
if not exist "%TEMP_OUTPUT%" goto :missing_output
move /Y "%TEMP_OUTPUT%" "%OUTPUT_FILE%" >nul
if errorlevel 1 goto :publish_failed

echo Packed "%OUTPUT_FILE%" from "%INDEX_FILE%".
exit /b 0

:usage
echo Usage: Drag pak_index.ini onto this file, or run:
echo   pack.bat path\to\pak_index.ini
exit /b 2

:missing_core
echo Error: PAK executable not found: "%CORE%"
exit /b 1

:missing_input
echo Error: Input index does not exist: "%~1"
exit /b 2

:pack_failed
echo Error: PAK packing failed with exit code %STATUS%.
call :remove_temporary_output
exit /b %STATUS%

:missing_output
echo Error: PAK executable succeeded but did not create "%TEMP_OUTPUT%".
exit /b 1

:stale_temporary_output
echo Error: Could not remove stale temporary output: "%TEMP_OUTPUT%"
exit /b 1

:publish_failed
echo Error: Could not replace "%OUTPUT_FILE%" with the packed output.
call :remove_temporary_output
exit /b 1

:remove_temporary_output
if exist "%TEMP_OUTPUT%" del /Q "%TEMP_OUTPUT%"
if exist "%TEMP_OUTPUT%" echo Warning: Could not remove "%TEMP_OUTPUT%".
exit /b 0
