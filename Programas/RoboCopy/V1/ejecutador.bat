@echo off
chcp 65001 > nul
title Herramienta Mover Archivos y Carpetas (Robocopy)

:: Ejecuta el script.ps1 ubicado en la misma carpeta que el ejecutable
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0script.ps1"

echo.
pause