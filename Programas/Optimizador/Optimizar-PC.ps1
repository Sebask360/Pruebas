# Verificar privilegios
if (-not ([Security.Principal.WindowsPrincipal] `
[Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Start-Process PowerShell `
    -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
    -Verb RunAs
    exit
}

# Ejecutar como Administrador

Write-Host "=== INICIANDO OPTIMIZACION ===" -ForegroundColor Green

# Activar Ultimate Performance
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null

$plan = powercfg -list | Select-String "Ultimate Performance"

if ($plan) {
    $guid = ($plan.ToString().Split()[3])
    powercfg -setactive $guid
}

# Limpiar temporales usuario
Write-Host "Limpiando temporales usuario..."
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# Limpiar temporales Windows
Write-Host "Limpiando temporales Windows..."
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Limpiar cache Windows Update
Write-Host "Limpiando cache Windows Update..."
net stop wuauserv
net stop bits

Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue

net start bits
net start wuauserv

# Desactivar transparencia
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f

# Ejecutar TRIM SSD
Write-Host "Optimizando SSD..."
defrag C: /L

# Reparar imagen Windows
Write-Host "Ejecutando DISM..."
DISM /Online /Cleanup-Image /RestoreHealth

# Verificar archivos sistema
Write-Host "Ejecutando SFC..."
sfc /scannow

Write-Host ""
Write-Host "=== OPTIMIZACION FINALIZADA ===" -ForegroundColor Green
Write-Host "Se recomienda reiniciar el equipo."