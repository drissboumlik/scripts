
param ($targetDirectory = $null)

if (-not $targetDirectory) {
    $targetDirectory = (Get-Location).Path
}

if (-not (Test-Path -Path $targetDirectory)) {
    Write-Host "`nDirectory '$targetDirectory' does not exist." -ForegroundColor DarkYellow
    exit 1
}


$errors = @()
$formatted = 0

# Ensure PSScriptAnalyzer is installed
if (-not (Get-Module PSScriptAnalyzer -ListAvailable)) {
    Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor Yellow
    Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck
}

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
            Kind            = 'space'
            IndentationSize = 4
        }

        PSUseConsistentWhitespace = @{
            CheckInnerBrace = $true
            CheckOpenBrace  = $true
            CheckOpenParen  = $true
            CheckOperator   = $true
            CheckPipe       = $true
            CheckSeparator  = $true
        }
    }
}

function Get-FileEncoding {
    param ([string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)

    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return [System.Text.UTF8Encoding]::new($true)
    }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return [System.Text.Encoding]::Unicode
    }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        return [System.Text.Encoding]::BigEndianUnicode
    }

    return [System.Text.UTF8Encoding]::new($false)
}

function Optimize-BlankLines {
    param ([string]$FilePath)

    $original = Get-Content -Path $FilePath -Raw

    # Collapse 3+ consecutive newlines (CRLF or LF) down to exactly one blank line
    $fixed = $original -replace '(\r?\n){3,}', "`r`n`r`n"

    if ($original -eq $fixed) {
        return $false
    }

    $encoding = Get-FileEncoding -Path $FilePath
    [System.IO.File]::WriteAllText($FilePath, $fixed, $encoding)
    return $true
}

Get-ChildItem "$targetDirectory\*.ps1" -Recurse -File | ForEach-Object {
    try {
        Write-Host "`n`nFormatting: $($_.FullName)`n" -ForegroundColor Cyan

        # Step 1 — PSScriptAnalyzer fixes (indentation, whitespace, braces, etc.)
        Invoke-ScriptAnalyzer -Path $_.FullName -Fix -Settings $settings

        # Step 2 — Collapse consecutive blank lines (PSScriptAnalyzer doesn't handle this)
        $trimmed = Optimize-BlankLines -FilePath $_.FullName
        if ($trimmed) {
            Write-Host "  [blank lines] collapsed in $($_.Name)" -ForegroundColor DarkGray
        }

        $formatted++
    } catch {
        $errors += "Error formatting file: $($_.FullName) - $_"
    }
}

Write-Host "`nFormatted $formatted files" -ForegroundColor Green

if ($errors.Count -gt 0) {
    Write-Host "`nErrors encountered:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
}