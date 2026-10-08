<# :
@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Get-Content '%~f0' -Raw)"
pause
exit /b
#>

Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;

function Mostrar-Encabezado {
    Clear-Host;
    Write-Host '===================================================' -ForegroundColor Cyan;
    Write-Host '   HERRAMIENTA DE TRANSFERENCIA ROBOCOPY v2.0' -ForegroundColor Cyan;
    Write-Host '===================================================' -ForegroundColor Cyan;
}

function Mostrar-Notificacion ($titulo,$texto) {
    try {
        [System.Media.SystemSounds]::Asterisk.Play();
        $balloon = New-Object System.Windows.Forms.NotifyIcon;
        $pathProc = Get-Process -id$pid | Select-Object -ExpandProperty Path;
        $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($pathProc);$balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info;
        $balloon.BalloonTipText =$texto;
        $balloon.BalloonTipTitle =$titulo;
        $balloon.Visible =$true;
        $balloon.ShowBalloonTip(5000);
    } catch { }
}

Mostrar-Encabezado;
Write-Host ' TIPO DE OPERACION:' -ForegroundColor Yellow;
Write-Host ' [1] Mover (Cortar - elimina del origen)';
Write-Host ' [2] Copiar (Duplicar - conserva el origen)';
Write-Host ' [3] Salir';
Write-Host '===================================================' -ForegroundColor Cyan;
$modoOp = Read-Host 'Selecciona una opcion (1-3)';

if ($modoOp -eq '3' -or $modoOp -notmatch '^[1-2]$') { exit; }
$esMover = ($modoOp -eq '1');

Mostrar-Encabezado;
Write-Host ' MODO DE EJECUCION:' -ForegroundColor Yellow;
Write-Host ' [1] Ejecucion Real';
Write-Host ' [2] Modo Prueba / Simulacion (Dry Run - no modifica archivos)';
Write-Host '===================================================' -ForegroundColor Cyan;
$dryRunOp = Read-Host 'Selecciona una opcion (1-2)';
$esDryRun = ($dryRunOp -eq '2');

Mostrar-Encabezado;
Write-Host ' CONTROL DE DUPLICADOS EN DESTINO:' -ForegroundColor Yellow;
Write-Host ' [1] Reemplazar siempre (Sobrescribir existentes)';
Write-Host ' [2] Omitir duplicados (No tocar si ya existe en destino)';
Write-Host ' [3] Actualizar solo si el origen es MAS RECIENTE';
Write-Host '===================================================' -ForegroundColor Cyan;
$dupOp = Read-Host 'Selecciona una opcion (1-3)';

$paramsDup = '';
switch ($dupOp) {
    '2' { $paramsDup = '/xc /xn /xo' }     '3' {$paramsDup = '/xo' }
    Default { $paramsDup = '' }
}

Mostrar-Encabezado;
Write-Host ' QUE DESEAS PROCESAR?:' -ForegroundColor Yellow;
Write-Host ' [1] Archivos Individuales (Seleccion multiple)';
Write-Host ' [2] Una Carpeta Especifica';
Write-Host ' [3] TODO el contenido de una Carpeta Origen';
Write-Host '===================================================' -ForegroundColor Cyan;
$tipoElemento = Read-Host 'Selecciona una opcion (1-3)';

$flagsRobocopy = '/r:1 /w:1 /mt:8';

if ($esDryRun) {$flagsRobocopy += ' /L';
    Write-Host "`n[!] ATENCION: Ejecutando en MODO PRUEBA / SIMULACION`n" -ForegroundColor Magenta;
}

switch ($tipoElemento) {     '1' {$ofd = New-Object System.Windows.Forms.OpenFileDialog;
        $ofd.Multiselect =$true;
        $ofd.Title = 'Selecciona los ARCHIVOS';
        if ($ofd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit; }

        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog;
        $fbd.Description = 'Selecciona la carpeta DESTINO';
        if ($fbd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit; }

        $files =$ofd.FileNames;
        $destino =$fbd.SelectedPath;
        $total =$files.Count;
        $exitos = 0; $errores = 0; $i = 0;

        $accionFlag = if ($esMover) { '/mov' } else { '' };

        foreach ($file in$files) {
            $i++;$percent = [math]::Round(($i / $total) * 100);
            $fileInfo = Get-Item -LiteralPath$file -ErrorAction SilentlyContinue;
            if (-not $fileInfo) {$errores++; continue; }

            $origenDir =$fileInfo.DirectoryName;
            $nombre =$fileInfo.Name;

            Write-Progress -Activity 'Procesando archivos...' -Status ("[{0}/{1}] {2}" -f $i,$total, $nombre) -PercentComplete$percent;

            $cmd = "robocopy `"$origenDir`" `"$destino`" `"$nombre`" $accionFlag $flagsRobocopy$paramsDup /njh /njs /nc /ns /np";
            Invoke-Expression $cmd | Out-Null;

            if ($LASTEXITCODE -le 1) {$exitos++;
                Write-Host " [OK] Archivo: $nombre" -ForegroundColor Green;
            } else {
                $errores++;
                Write-Host " [ERROR] Archivo: $nombre" -ForegroundColor Red;
            }
        }
        Write-Progress -Activity 'Procesando archivos...' -Completed;
    }

    '2' {
        $fbdOrigen = New-Object System.Windows.Forms.FolderBrowserDialog;
        $fbdOrigen.Description = 'Selecciona la CARPETA a procesar';
        if ($fbdOrigen.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit; }

        $fbdDestino = New-Object System.Windows.Forms.FolderBrowserDialog;
        $fbdDestino.Description = 'Selecciona la carpeta DESTINO';
        if ($fbdDestino.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit; }

        $carpetaOrigen = Get-Item -LiteralPath$fbdOrigen.SelectedPath;
        $destinoFinal = Join-Path -Path $fbdDestino.SelectedPath -ChildPath$carpetaOrigen.Name;

        $accionFlag = if ($esMover) { '/move /e