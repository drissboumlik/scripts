
param ($targetDirectory = $null)

if (-not $targetDirectory) {
    $targetDirectory = (Get-Location).Path
}


$errors = @()
$formatted = 0

# Ensure PSScriptAnalyzer is installed
if (-not (Get-Module PSScriptAnalyzer -ListAvailable)) {
    Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor Yellow
    Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck
}


# Import the module
Import-Module PSScriptAnalyzer -Force

$IncludeRules = @('AvoidSemicolonsAsLineTerminators')
$ExcludeRules = @('PSUseSingularNouns')

Get-ChildItem "$targetDirectory\*.ps1" -Recurse -File | ForEach-Object {
    try {
        Write-Host "`n`nFormatting: $($_.FullName)`n" -ForegroundColor Cyan
        # Build parameter splat for Invoke-ScriptAnalyzer so include/exclude/settings are optional
        $invokeParams = @{
            Path = $_.FullName
            Fix  = $true
        }

        if ($IncludeRules -and $IncludeRules.Count -gt 0) {
            $invokeParams.IncludeRule = $IncludeRules
        }
        if ($ExcludeRules -and $ExcludeRules.Count -gt 0) {
            $invokeParams.ExcludeRule = $ExcludeRules
        }
        
        Invoke-ScriptAnalyzer @invokeParams
        # Invoke-ScriptAnalyzer -Path $_.FullName -Fix -ExcludeRule PSUseSingularNouns
        $formatted++
    } catch {
        $errors += "Error formatting file: $($_.FullName) - $_"
    }
}

Write-Host "`nFormatted $formatted files" -ForegroundColor Green
if ($errors.Count -gt 0) {
    Write-Host "Errors encountered:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
}