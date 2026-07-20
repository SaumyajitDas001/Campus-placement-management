@echo off
setlocal

echo ========================================
echo PostgreSQL Local Database Setup
echo ========================================

set DB_NAME=campus_placement
set DB_USER=postgres
set DB_PASSWORD=Saumyajit@2004
set DB_HOST=localhost
set DB_PORT=5433

echo.
echo This script uses your local PostgreSQL user: %DB_USER%
echo Port: %DB_PORT%
echo.

echo [1/3] Creating database if missing...
set PGPASSWORD=%DB_PASSWORD%
createdb -h %DB_HOST% -p %DB_PORT% -U %DB_USER% %DB_NAME% 2>nul
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT current_database();"
if errorlevel 1 goto error

echo.
echo [2/3] Loading schema...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f sql\01_schema.sql
if errorlevel 1 goto error

echo.
echo [3/3] Loading seed data...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f sql\02_seed.sql
if errorlevel 1 goto error

echo.
echo Database setup complete.
echo Connection string:
echo postgresql://postgres:Saumyajit%%402004@localhost:5433/campus_placement
goto end

:error
echo.
echo Database setup failed.
echo Check that PostgreSQL is running and that psql is available in PATH.
exit /b 1

:end
endlocal
