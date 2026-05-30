
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

$settings = @{
    IncludeRules = @(
        'PSUseConsistentIndentation'
        'PSUseConsistentWhitespace'
        'PSPlaceOpenBrace'
        'PSPlaceCloseBrace'
        'PSAlignAssignmentStatement'
        'PSAvoidTrailingWhitespace'
        'PSAvoidSemicolonsAsLineTerminators'
        'PSPossibleIncorrectComparisonWithNull'
        'PSPossibleIncorrectUsageOfAssignmentOperator'
        'PSAvoidLongLines'
    )

    Rules = @{
        PSUseConsistentIndentation = @{
            Kind = 'space'
            IndentationSize = 4
        }

        PSUseConsistentWhitespace = @{
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckSeparator = $true
        }
    }
}

Get-ChildItem "$targetDirectory\*.ps1" -Recurse -File | ForEach-Object {
    try {
        Write-Host "`n`nFormatting: $($_.FullName)`n" -ForegroundColor Cyan

        Invoke-ScriptAnalyzer -Path $_.FullName -Fix -Settings $settings
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