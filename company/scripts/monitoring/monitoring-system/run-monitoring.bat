@echo off
cd /d "%~dp0\.."
powershell -ExecutionPolicy Bypass -File ".\monitoring-system\daily-monitoring.ps1" -Automated
