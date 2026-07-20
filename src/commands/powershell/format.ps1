
param ($targetDirectory = $null)

if (-not $targetDirectory) {
    $targetDirectory = (Get-Location).Path
}

if (-not (Test-Path -Path $targetDirectory)) {
    Write-Host "`nDirectory '$targetDirectory' does not exist." -ForegroundColor DarkYellow
    exit 1
}


$errors    = @()
$formatted = 0
$functionViolationsSummary = @()
$results   = @()

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
        'PSUseApprovedVerbs'
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

function Save-File {
    param ([string]$Path, [string]$Content)

    $encoding = Get-FileEncoding -Path $Path
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

# ---------------------------------------------------------------------------
# Rule: Collapse 3+ consecutive blank lines down to exactly one blank line
# ---------------------------------------------------------------------------
function Optimize-BlankLines {
    param ([string]$Content)

    return $Content -replace '(\r?\n){3,}', "`r`n`r`n"
}

# ---------------------------------------------------------------------------
# Rule: Remove blank lines at the top of a function body (after opening brace)
# ---------------------------------------------------------------------------
function Optimize-FunctionBodyStart {
    param ([string]$Content)

    return $Content -replace '(\{[ \t]*\r?\n)(\s*\r?\n)+', '$1'
}

# ---------------------------------------------------------------------------
# Rule: Remove blank lines between param block closing paren and try {
# ---------------------------------------------------------------------------
function Optimize-ParamToTrySpacing {
    param ([string]$Content)

    return $Content -replace '(\))\s*(\r?\n)(\s*(\r?\n)+)(\s*try\s*\{)', '$1$2$5'
}

# ---------------------------------------------------------------------------
# Rule: Ensure exactly one blank line between param block close and try {
# ---------------------------------------------------------------------------
function Optimize-ParamToTryBlankLine {
    param ([string]$Content)

    return $Content -replace '(\))([ \t]*\r?\n)([ \t]*try\s*\{)', '$1$2$2$3'
}

# ---------------------------------------------------------------------------
# Rule: Exactly one blank line between function definitions
# ---------------------------------------------------------------------------
function Optimize-FunctionSpacing {
    param ([string]$Content)

    # Remove all blank lines between closing brace of one function and start of next
    $Content = $Content -replace '(\}[ \t]*\r?\n)(\s*\r?\n)+([ \t]*function\s)', '$1$3'

    # Ensure exactly one blank line between them
    $Content = $Content -replace '(\})([ \t]*\r?\n)([ \t]*function\s)', '$1$2$2$3'

    return $Content
}

# ---------------------------------------------------------------------------
# Rule: Remove blank lines immediately before a closing brace
# ---------------------------------------------------------------------------
function Optimize-BlankLinesBeforeClosingBrace {
    param ([string]$Content)

    return $Content -replace '(\r?\n)(\s*\r?\n)+([ \t]*\})', '$1$3'
}

# ---------------------------------------------------------------------------
# Rule: Remove blank lines immediately after try/catch/finally opening brace
# ---------------------------------------------------------------------------
function Optimize-TryCatchBodyStart {
    param ([string]$Content)

    return $Content -replace '(\b(try|catch|finally)\b[^{]*\{[ \t]*\r?\n)(\s*\r?\n)+', '$1'
}

# ---------------------------------------------------------------------------
# Rule: Enforce PowerShell function naming convention Verb-Noun
# ---------------------------------------------------------------------------
function Test-FunctionNameConvention {
    param ([string]$Content)

    $violations = [System.Collections.Generic.List[string]]::new()

    foreach ($match in [regex]::Matches($Content, '(?im)^\s*function\s+(?<name>[A-Za-z][A-Za-z0-9]*)\s*\{')) {
        $name = $match.Groups['name'].Value

        if ($name -notmatch '^[A-Za-z][A-Za-z0-9]*-[A-Za-z][A-Za-z0-9]*$') {
            $violations.Add($name)
        }
    }

    return $violations
}

# ---------------------------------------------------------------------------
# Pre-pass: Normalize mixed line endings to CRLF before anything else runs
# ---------------------------------------------------------------------------
function Optimize-LineEndings {
    param ([string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $text  = [System.Text.Encoding]::UTF8.GetString($bytes)
    $text = $text.TrimStart([char]0xFEFF)

    # Normalize all line endings to LF first, then convert to CRLF
    $normalized = $text -replace "`r`n", "`n" -replace "`r", "`n" -replace "`n", "`r`n"

    if ($normalized -eq $text) {
        return $false
    }

    $encoding = Get-FileEncoding -Path $Path
    [System.IO.File]::WriteAllText($Path, $normalized, $encoding)
    return $true
}

# ---------------------------------------------------------------------------
# Orchestrator: run all custom rules in the correct order
# ---------------------------------------------------------------------------
function Invoke-FileFormatRules {
    param ([string]$FilePath)

    $original = Get-Content -Path $FilePath -Raw
    $content  = $original
    $content  = $original.TrimStart([char]0xFEFF)

    # Structural / blank line rules first
    $content = Optimize-BlankLines                 -Content $content
    $content = Optimize-FunctionBodyStart          -Content $content
    $content = Optimize-TryCatchBodyStart          -Content $content
    $content = Optimize-BlankLinesBeforeClosingBrace -Content $content
    $content = Optimize-ParamToTrySpacing          -Content $content
    $content = Optimize-ParamToTryBlankLine        -Content $content
    $content = Optimize-FunctionSpacing            -Content $content

    $functionViolations = Test-FunctionNameConvention -Content $content

    if ($content -eq $original -and $functionViolations.Count -eq 0) {
        return [pscustomobject]@{
            Changed            = $false
            FunctionViolations = @()
        }
    }

    if ($content -ne $original) {
        Save-File -Path $FilePath -Content $content
    }

    return [pscustomobject]@{
        Changed            = $content -ne $original
        FunctionViolations = @($functionViolations)
    }
}

Get-ChildItem "$targetDirectory\*.ps1" -Recurse -File | ForEach-Object {
    try {
        $fileFullName = $_.FullName
        $fileName = $_.Name

        # Pre-pass — normalize line endings before PSScriptAnalyzer runs
        $lineEndingsFixed = Optimize-LineEndings -Path $fileFullName

        # Step 1 — PSScriptAnalyzer fixes (indentation, whitespace, braces, etc.)
        Invoke-ScriptAnalyzer -Path $fileFullName -Fix -Settings $settings

        # Step 2 — Custom formatting rules
        $ruleResult = Invoke-FileFormatRules -FilePath $fileFullName

        $result = "formatted"
        if ($ruleResult.FunctionViolations.Count -gt 0) {
            $functionViolationsSummary += foreach ($functionName in $ruleResult.FunctionViolations) {
                [pscustomobject]@{
                    File         = $fileName
                    FunctionName = $functionName
                }
            }

            $errors += "Function names in $fileName should use the Verb-Noun convention: $($ruleResult.FunctionViolations -join ', ')"
            $result = "naming violations"
        }

        $results += [pscustomobject]@{
            FileName = $fileName
            Result   = $result
        }

        $formatted++
    } catch {
        $errors += "Error formatting file: $($fileFullName) - $_"
        $results += [pscustomobject]@{
            FileName = $_.Name
            Result   = "error"
        }
    }
}

Write-Host "`nFormatted $formatted files`n" -ForegroundColor Green

$results | ForEach-Object {
    $fileName = $_.FileName
    $result = $_.Result
    $dots = '.' * (50 - $fileName.Length)
    Write-Host "$fileName $dots $result"
}

if ($functionViolationsSummary.Count -gt 0) {
    Write-Host "`nFunction naming violations:" -ForegroundColor Yellow
    $functionViolationsSummary | ForEach-Object {
        Write-Host " - $($_.File): $($_.FunctionName)" -ForegroundColor Yellow
    }
}

if ($errors.Count -gt 0) {
    Write-Host "`nErrors encountered:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
}
