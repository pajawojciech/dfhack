@echo off

REM Store current directory
set ORIGINAL_DIR=%CD%

REM Read the DF_PATH from DF_PATH.txt
set /p DF_PATH=<DF_PATH.txt

REM Create the hack/lua/plugins directory in DF folder if it doesn't exist
if not exist "%DF_PATH%\hack\lua\plugins" mkdir "%DF_PATH%\hack\lua\plugins"

REM Copy the lua files
echo Copying orders.lua to %DF_PATH%\hack\lua\plugins\
copy "..\..\plugins\lua\orders.lua" "%DF_PATH%\hack\lua\plugins\"

echo Copying orders_translate.lua to %DF_PATH%\hack\lua\plugins\
copy "..\..\plugins\lua\orders_translate.lua" "%DF_PATH%\hack\lua\plugins\"

REM Kill any running Dwarf Fortress processes
echo Killing any running Dwarf Fortress processes...
taskkill /f /im "Dwarf Fortress.exe" 2>nul

REM Wait a moment for processes to fully terminate
timeout /t 1 /nobreak >nul

REM Run Dwarf Fortress directly
echo Starting Dwarf Fortress...
cd /d "%DF_PATH%"
start "" "Dwarf Fortress.exe"

REM Return to original directory
cd /d "%ORIGINAL_DIR%"