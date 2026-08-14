@echo off
REM ============================================================
REM GhostFix one-click launcher | GhostFix 一键启动脚本
REM Launches the GhostFix GUI via PowerShell
REM 通过 PowerShell 启动 GhostFix 图形界面
REM ============================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GhostFix.ps1"
