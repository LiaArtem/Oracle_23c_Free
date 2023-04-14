cd %cd%
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& './oracle.ps1'"

PowerShell -command "Start-Sleep -s 40"
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& './oracle_sql.ps1'"

pause
