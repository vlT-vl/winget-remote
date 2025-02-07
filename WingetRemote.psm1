# WingetRemote.psm1 <> powershell module
# Copyright © 2025 vlT di Veronesi Lorenzo
#******************************************************************************

$global:WingetRemoteVersion = "v0.0.1"
$global:WingetRemoteBuild = "R001-07022025"

function enable-localmanifest {
    # Verifica se l'utente corrente ha privilegi di amministratore.
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host ""
        Write-Host "🔴 Il comando richiede privilegi amministrativi. Verrà richiesto il prompt UAC." -ForegroundColor Red
        Start-Process -FilePath "winget.exe" -ArgumentList "settings --enable LocalManifestFiles" -Verb RunAs -Wait
    }
    else {
        winget.exe settings --enable LocalManifestFiles
    }
}

function remote {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Url
    )
    try {
        if (-not $Url) {
            throw "❌ URL del manifest non specificato."
        }

        # Controlla se l'argomento è un'opzione speciale
        if ($Url -eq "--version") {
            Write-Host "winget remote [version]: $global:WingetRemoteVersion" -ForegroundColor Cyan
            return
        }
        elseif ($Url -eq "--build") {
            Write-Host "winget remote [build]: $global:WingetRemoteBuild" -ForegroundColor Cyan
            return
        }

        # Abilita la funzionalità dei file manifest locali (richiede privilegio amministrativo)
        enable-localmanifest

        # Percorso temporaneo per il file manifest
        $manifestPath = Join-Path $env:TEMP "remote-manifest.yaml"

        Write-Host ""
        Write-Host "🔄 Download del manifest da: $Url ..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $Url -OutFile $manifestPath -UseBasicParsing

        Write-Host ""
        Write-Host "🔄 Valido il manifest scaricato, prima di procedere con installazione..." -ForegroundColor Yellow
        $validateOutput = winget.exe validate --manifest $manifestPath 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Manifest valido. Procedo con l'installazione..." -ForegroundColor Green
            winget.exe install --manifest $manifestPath --silent
        }
        else {
            Write-Host "❌ Manifest non valido. Dettagli: $validateOutput" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Errore durante l'operazione: $_" -ForegroundColor Red
    }
}

function winget {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    if ($Args.Count -ge 1 -and $Args[0].ToLower() -eq "remote") {
        if ($Args.Count -eq 1) {
            Write-Host "winget remote" -ForegroundColor blue
            Write-Host "copyright © 2025 vlT di Veronesi Lorenzo"
            Write-Host ""
            Write-Host "installare manifest remoti --> winget remote <URL>" -ForegroundColor Cyan
            Write-Host "versione --> winget remote --version" -ForegroundColor Cyan
            Write-Host "build --> winget remote --build" -ForegroundColor Cyan
            return
        }
        else {
            remote -Url $Args[1]
        }
    }
    else {
        winget.exe @Args
    }
}
