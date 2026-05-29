@echo off
REM Company-Information Org OS - Development Startup Script
REM This script starts all services needed for local development

echo ===========================================
echo  AI-Whisperers Org OS - Development Setup
echo ===========================================
echo.

REM Check and install dependencies if needed
echo Checking dependencies...

if not exist "node_modules\" (
    echo Installing root dependencies...
    call npm install --legacy-peer-deps
)

if not exist "apps\dashboard\node_modules\" (
    echo Installing dashboard dependencies...
    cd apps\dashboard
    call npm install --legacy-peer-deps
    cd ..\..
)

if not exist "services\jobs\node_modules\" (
    echo Installing backend dependencies...
    cd services\jobs
    call npm install --legacy-peer-deps
    cd ..\..
)

REM Check if database exists
if not exist "services\jobs\dev.db" (
    echo Setting up database...
    cd services\jobs
    call npx prisma generate
    call npx prisma migrate dev --name init
    cd ..\..
)

echo.
echo Starting services...
echo.

REM Start services in new command windows
echo Starting Dashboard on http://localhost:3000
start "Org OS Dashboard" cmd /k "cd apps\dashboard && npm run dev"

timeout /t 2 /nobreak >nul

echo Starting Backend API on http://localhost:4000
start "Org OS Backend" cmd /k "cd services\jobs && npm run dev"

echo.
echo ===========================================
echo           Services Starting Up
echo ===========================================
echo.
echo Dashboard:    http://localhost:3000
echo Backend API:  http://localhost:4000
echo API Docs:     http://localhost:4000/api
echo Health Check: http://localhost:4000/health
echo.
echo Press any key to exit this window...
echo (Services will continue running in their own windows)
pause >nul