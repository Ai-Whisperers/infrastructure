@echo off
echo ============================================
echo    AI WHISPERERS PROJECT DASHBOARD
echo ============================================
echo.

:: Check if Node.js is installed
where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

:: Install dependencies if needed
if not exist node_modules (
    echo Installing dependencies...
    npm install
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to install dependencies
        pause
        exit /b 1
    )
)

:: Start the dashboard server
echo Starting dashboard server...
echo.
echo Dashboard will be available at: http://localhost:3001
echo Press Ctrl+C to stop the server
echo.

:: Open browser after a short delay
start /min cmd /c "timeout /t 3 /nobreak >nul && start http://localhost:3001"

:: Run the server
node api-server.js