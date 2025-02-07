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
            winget.exe install --manifest $manifestPath
        }
        else {
            Write-Host ""
            Write-Host "❌ Manifest non valido. Dettagli: $validateOutput" -ForegroundColor Red
        }
    }
    catch {
        Write-Host ""
        Write-Host "❌ Errore durante l'operazione: $_" -ForegroundColor Red
    }
}

function argspars {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )
    $url = $Arguments[0]

    # Controlla se l'utente ha richiesto la versione del modulo
    if ($url -eq "-v") {
        Write-Host "winget remote build: $global:WingetRemoteVersion" -ForegroundColor Cyan
        return
    }

    # Controlla se l'utente ha richiesto la build del modulo
    if ($url -eq "--build") {
        Write-Host "winget remote build: $global:WingetRemoteBuild" -ForegroundColor Cyan
        return
    }

    # Verifica che l'argomento sia un URL valido
    if (-not [Uri]::IsWellFormedUriString($url, [UriKind]::Absolute)) {
        Write-Host "❌ L'argomento fornito non è un URL valido." -ForegroundColor Red
        return
    }

    # Verifica che l'URL termini con '.yaml'
    if (-not $url.ToLower().EndsWith(".yaml")) {
        Write-Host "❌ L'URL deve puntare a un file con estensione .yaml." -ForegroundColor Red
        return
    }

    remote -Url $url
}

function winget {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )
    # Se il primo argomento è "remote", gestisce il comando custom.
    if ($Args.Count -ge 1 -and $Args[0].ToLower() -eq "remote") {
        if ($Args.Count -eq 1) {
          Write-Host "winget remote" -ForegroundColor blue
          Write-Host "copyright © 2025 vlT di Veronesi Lorenzo"
          Write-Host ""
          Write-Host "per installare manifest remoti --> winget remote <URL>" -ForegroundColor Cyan
            return
        }
        else {
            $remoteArgs = $Args[1..($Args.Count - 1)]
            argspars -Arguments $remoteArgs
        }
    }
    else {
        # Per tutti gli altri comandi, inoltra gli argomenti a winget.exe.
        winget.exe @Args
    }
}

# Esporta solamente la funzione wrapper 'winget'
# Export-ModuleMember -Function winget
