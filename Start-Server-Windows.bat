@echo off
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 (
    python server\launch.py --host 0.0.0.0
) else (
    py -3 server\launch.py --host 0.0.0.0
)
pause
