@echo off
::powershell.exe -NoProfile -Sta -WindowStyle Hidden -File "%~dp0citrix-maintenance-scheduler.ps1"
powershell.exe -NoProfile -Sta -File "%~dp0citrix-maintenance-mode-scheduler.ps1"
