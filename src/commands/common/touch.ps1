# To run this script:
# powershell -ExecutionPolicy Bypass -File "path\to\script\touch.ps1" path/to/file.ext

# You might need to run this before: Set-ExecutionPolicy Bypass -Scope Process -Force if you are using powershell


param ( [string]$FilePath )

try {
    if (-not $FilePath) {
        Write-Host "Error: Please provide a file path to create." -ForegroundColor DarkYellow
        exit 1
    }

    # Normalize path to use the current OS directory separator
    $normalizedPath = $FilePath -replace '[\\/]', [IO.Path]::DirectorySeparatorChar

    # Extract directory and file parts
    $directoryPath = Split-Path -Path $normalizedPath -Parent
    $fileName = Split-Path -Path $normalizedPath -Leaf

    # Check if the directory path exists as a file
    if (Test-Path -Path $directoryPath -PathType Leaf) {
        throw "The path '$directoryPath' exists as a file, not a directory. Cannot create the required structure."
    }

    # Create intermediate directories if necessary
    if (-not (Test-Path -Path $directoryPath)) {
        New-Item -ItemType Directory -Path $directoryPath -Force > $null
    }

    # Create the file
    $fileFullPath = Join-Path -Path $directoryPath -ChildPath $fileName
    if (-not (Test-Path -Path $fileFullPath)) {
        New-Item -ItemType File -Path $fileFullPath > $null
    }

    Write-Host "File created successfully: $fileFullPath" -ForegroundColor DarkGreen
} catch {
    # Display a friendly error message
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor DarkYellow
}
