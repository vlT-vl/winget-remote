# wingetremote.psm1 <> powershell module
#******************************************************************************

function remote {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Url
    )
    try {
        if (-not $Url) {
            throw "URL del manifest non specificato."
        }

        #Write-Host "Abilito Funzionalità installzione manifest locali..."
        localmanifestenabler

        # Salva il manifesto in una posizione temporanea
        $manifestPath = Join-Path $env:TEMP "remote-manifest.yaml"

        Write-Host "Download del manifest: $Url ..."
        Invoke-WebRequest -Uri $Url -OutFile $manifestPath -UseBasicParsing

        Write-Host "Validazione manifest.."
        $validateOutput = winget.exe validate --manifest $manifestPath 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Manifest valido. Procedo con l'installazione..."
            winget.exe install --manifest $manifestPath
        }
        else {
            Write-Error "Validazione del manifest fallita. Dettagli: $validateOutput"
        }
    }
    catch {
        Write-Error "Errore: $_"
    }
}

function localmanifestenabler {
    # Verifica se l'utente corrente ha privilegi di amministratore.
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Il comando richiede privilegi amministrativi. Verrà richiesto il prompt UAC."
        Start-Process -FilePath "winget.exe" -ArgumentList "settings --enable LocalManifestFiles" -Verb RunAs -Wait
    }
    else {
        winget.exe settings --enable LocalManifestFiles
    }
}

function argspars {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )
    if ($Arguments.Count -lt 1) {
        Write-Host "Utilizzo corretto: winget remote <URL>"
        return
    }

    $url = $Arguments[0]

    # Verifica che l'argomento sia un URL valido
    if (-not [Uri]::IsWellFormedUriString($url, [UriKind]::Absolute)) {
        Write-Error "L'argomento fornito non è un URL valido."
        return
    }

    # Verifica che l'URL termini con '.yaml'
    if (-not $url.ToLower().EndsWith(".yaml")) {
        Write-Error "L'URL deve puntare a un file con estensione .yaml."
        return
    }
    remote -Url $url
}

function winget {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )
    # Se il primo argomento è "remote"...
    if ($Args.Count -ge 1 -and $Args[0].ToLower() -eq "remote") {
        if ($Args.Count -eq 1) {
            Write-Host "Utilizzo corretto: winget remote <URL>"
            return
        }
        else {
            $remoteArgs = $Args[1..($Args.Count - 1)]
            argspars -Arguments $remoteArgs
        }
    }
    else {
        # Per tutte le altre chiamate inoltra gli argomenti a winget.exe
        winget.exe @Args
    }
}

# Esporta solamente la funzione wrapper 'winget'
#Export-ModuleMember -Function winget
