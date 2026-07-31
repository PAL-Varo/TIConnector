# TIConnector.psm1

# 1. Load private helper functions
$privateFunctions = Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue
foreach ($file in $privateFunctions) {
    try {
        . $file.FullName
    }
    catch {
        Write-Error "Failed to load private function '$($file.Name)': $_"
    }
}

# 2. Load public cmdlets
$publicFunctions = Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue
foreach ($file in $publicFunctions) {
    try {
        . $file.FullName
    }
    catch {
        Write-Error "Failed to load public function '$($file.Name)': $_"
    }
}
