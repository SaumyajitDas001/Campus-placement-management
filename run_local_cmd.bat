@echo off
setlocal

echo ========================================
echo Campus Placement Management System
echo Local CMD Runner
echo ========================================

set DB_NAME=campus_placement
set DB_USER=postgres
set DB_PASSWORD=Saumyajit@2004
set DB_HOST=localhost
set DB_PORT=5433

echo.
echo [1/5] Creating PostgreSQL database if it does not exist...
set PGPASSWORD=%DB_PASSWORD%
createdb -h %DB_HOST% -p %DB_PORT% -U %DB_USER% %DB_NAME% 2>nul
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT current_database();"
if errorlevel 1 goto error

echo.
echo [2/5] Loading schema...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f sql\01_schema.sql
if errorlevel 1 goto error

echo.
echo [3/5] Loading seed data...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f sql\02_seed.sql
if errorlevel 1 goto error

echo.
echo [4/5] Installing Python dependencies...
if not exist .venv (
    python -m venv .venv
)
call .venv\Scripts\activate.bat
python -m pip install -r requirements.txt
if errorlevel 1 goto error

echo.
echo [5/5] Starting Flask app...
set DATABASE_URL=postgresql://postgres:Saumyajit%%402004@localhost:5433/campus_placement
echo Open this URL in your browser:
echo http://localhost:5000
echo.
flask --app app run
goto end

:error
echo.
echo Something failed. Check whether PostgreSQL is running and psql/createdb are available in PATH.
exit /b 1

:end
endlocal
