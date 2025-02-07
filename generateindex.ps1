$manifestBaseUrl = "https://raw.githubusercontent.com/vlT-vl/winget-remote/refs/heads/main/manifest/"

# Funzione per generare l'index
function Generate-Index {
    param (
        [string]$manifestDirectory,
        [string]$outputFile
    )

    $index = @()
    $manifestLastUpdate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

    # Recupera tutti i file YAML nella directory
    $files = Get-ChildItem -Path $manifestDirectory -Filter "*.yaml"

    foreach ($file in $files) {
        $manifest = Get-Content -Path $file.FullName | ConvertFrom-Yaml
        $manifestUrl = "$manifestBaseUrl$($file.Name)"

        $packageInfo = @{
            "Id" = $manifest.Id
            "Name" = $manifest.Name
            "Version" = $manifest.Version
            "Publisher" = $manifest.Publisher
            "ManifestURL" = $manifestUrl
        }

        $index += $packageInfo
    }

    # Converti l'array in JSON e scrivilo su file
    $outputData = @{ "ManifestLastUpdate" = $manifestLastUpdate; "Packages" = $index }
    $outputData | ConvertTo-Json -Depth 2 | Set-Content -Path $outputFile
}

# Esegui la funzione con i percorsi richiesti
Generate-Index -manifestDirectory "./manifest" -outputFile "./manifest/.index.json"
