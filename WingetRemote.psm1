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

        Write-Host "Abilito Funzionalità installzione manifest locali..."
        winget.exe settings --enable LocalManifestFiles

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

function argspars {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )
    if ($Arguments.Count -lt 1) {
        Write-Error "URL del manifest non specificato. Utilizzo corretto: winget remote <URL>"
        return
    }

    # Il primo argomento è considerato l'URL del manifesto
    $url = $Arguments[0]
    remote -Url $url
}

function winget {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )
    # Se il primo argomento è "remote", utilizza il comando custom
    if ($Args.Count -ge 1 -and $Args[0].ToLower() -eq "remote") {
        $remoteArgs = if ($Args.Count -gt 1) { $Args[1..($Args.Count - 1)] } else { @() }
        argspars -Arguments $remoteArgs
    }
    else {
        # Per tutti gli altri comandi inoltra gli argomenti a winget.exe
        winget.exe @Args
    }
}

# Esporta solamente la funzione wrapper 'winget'
Export-ModuleMember -Function winget
