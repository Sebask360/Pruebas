Add-Type -AssemblyName System.Windows.Forms

function Mostrar-Menu {
    Clear-Host
    Write-Host '===================================================' -ForegroundColor Cyan
    Write-Host '   HERRAMIENTA DE TRANSFERENCIA CON ROBOCOPY' -ForegroundColor Cyan
    Write-Host '===================================================' -ForegroundColor Cyan
    Write-Host ' [1] Mover Archivos Individuales (Seleccion multiple)'
    Write-Host ' [2] Mover una Carpeta Especifica'
    Write-Host ' [3] Mover TODO el contenido de una Carpeta Origen'
    Write-Host ' [4] Salir'
    Write-Host '===================================================' -ForegroundColor Cyan
    Write-Host ''
}

Mostrar-Menu
$opcion = Read-Host 'Selecciona una opcion (1-4)'

switch ($opcion) {
    '1' {
        # --- OPCION 1: ARCHIVOS INDIVIDUALES ---
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Multiselect = $true
        $ofd.Title = 'Selecciona los ARCHIVOS a mover'
        if ($ofd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { 
            exit 
        }

        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = 'Selecciona la carpeta DESTINO'
        if ($fbd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { 
            exit 
        }

        $files = $ofd.FileNames
        $destino = $fbd.SelectedPath
        $total = $files.Count
        $exitos = 0
        $errores = 0
        $i = 0

        Write-Host ""
        Write-Host "Iniciando movido de $total archivo(s)..." -ForegroundColor Cyan
        Write-Host ""

        foreach ($file in $files) {
            $i++
            $percent = [math]::Round(($i / $total) * 100)
            $fileInfo = Get-Item -LiteralPath $file -ErrorAction SilentlyContinue
            if (-not $fileInfo) { 
                $errores++
                continue 
            }

            $origenDir = $fileInfo.DirectoryName
            $nombre = $fileInfo.Name

            Write-Progress -Activity 'Moviendo archivos...' -Status ("[{0}/{1}] {2}" -f $i, $total, $nombre) -PercentComplete $percent

            # Ejecución de Robocopy
            robocopy "$origenDir" "$destino" "$nombre" /mov /njh /njs /nc /ns /np /r:1 /w:1 | Out-Null

            if ($LASTEXITCODE -le 1) {
                $exitos++
                Write-Host " [OK] Archivo: $nombre" -ForegroundColor Green
            } else {
                $errores++
                Write-Host " [ERROR] Archivo: $nombre" -ForegroundColor Red
            }
        }
        Write-Progress -Activity 'Moviendo archivos...' -Completed
    }

    '2' {
        # --- OPCION 2: UNA CARPETA ESPECIFICA ---
        Write-Host ""
        Write-Host "[+] Selecciona la carpeta que deseas mover..." -ForegroundColor Yellow
        $fbdOrigen = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbdOrigen.Description = 'Selecciona la CARPETA a mover'
        if ($fbdOrigen.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { 
            exit 
        }

        Write-Host "[+] Selecciona la carpeta de destino..." -ForegroundColor Yellow
        $fbdDestino = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbdDestino.Description = 'Selecciona la carpeta DESTINO'
        if ($fbdDestino.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { 
            exit 
        }

        $carpetaOrigen = Get-Item -LiteralPath $fbdOrigen.SelectedPath
        $destinoBase = $fbdDestino.SelectedPath
        $destinoFinal = Join-Path -Path $destinoBase -ChildPath $carpetaOrigen.Name

        Write-Host ""
        Write-Host "Moviendo carpeta: $($carpetaOrigen.Name)..." -ForegroundColor Cyan

        # Robocopy para mover estructura completa (/move /e)
        robocopy "$($carpetaOrigen.FullName)" "$destinoFinal" /move /e /r:1 /w:1 /mt:8

        if ($LASTEXITCODE -le 7) {
            $exitos = 1
            $errores = 0
            Write-Host ""
            Write-Host " [OK] Carpeta '$($carpetaOrigen.Name)' movida con exito." -ForegroundColor Green
        } else {
            $exitos = 0
            $errores = 1
            Write-Host ""
            Write-Host " [ERROR] Ocurrio un problema al mover la carpeta." -ForegroundColor Red
        }
        $total = 1
    }

    '3' {
        # --- OPCION 3: TODO EL CONTENIDO DE UNA CARPETA ---
        Write-Host ""
        Write-Host "[+] Selecciona la carpeta ORIGEN (Se movera TODO su contenido)..." -ForegroundColor Yellow
        $fbdOrigen = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbdOrigen.Description = 'Selecciona la carpeta ORIGEN'
        if ($fbdOrigen.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { 
            exit 
        }

        Write-Host "[+] Selecciona la carpeta DESTINO..." -ForegroundColor Yellow
        $fbdDestino = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbdDestino.Description = 'Selecciona la carpeta DESTINO'
        if ($fbdDestino.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { 
            exit 
        }

        $origen = $fbdOrigen.SelectedPath
        $destino = $fbdDestino.SelectedPath

        Write-Host ""
        Write-Host "Moviendo todo el contenido de '$origen' a '$destino'..." -ForegroundColor Cyan

        # Mueve todo el contenido directamente
        robocopy "$origen" "$destino" /move /e /r:1 /w:1 /mt:8

        if ($LASTEXITCODE -le 7) {
            $exitos = 1
            $errores = 0
            Write-Host ""
            Write-Host " [OK] Contenido transferido con exito." -ForegroundColor Green
        } else {
            $exitos = 0
            $errores = 1
            Write-Host ""
            Write-Host " [ERROR] Fallo al mover algunos elementos." -ForegroundColor Red
        }
        $total = 1
    }

    Default {
        Write-Host '[!] Operacion cancelada o seleccion invalida.' -ForegroundColor Yellow
        exit
    }
}

# 5. Resumen final
Write-Host ""
Write-Host '===================================================' -ForegroundColor Cyan
Write-Host '   RESUMEN DEL PROCESO' -ForegroundColor Cyan
Write-Host '===================================================' -ForegroundColor Cyan
Write-Host " Operaciones procesadas: $total"
Write-Host " Exitosas:               $exitos" -ForegroundColor Green
if ($errores -gt 0) {
    Write-Host " Fallidas/Con error:     $errores" -ForegroundColor Red
} else {
    Write-Host " Fallidas/Con error:     0" -ForegroundColor Green
}
Write-Host '===================================================' -ForegroundColor Cyan