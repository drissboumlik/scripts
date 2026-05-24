# To run this script:
# powershell -ExecutionPolicy Bypass -File "path\to\script\toggle-xdebug.ps1" -envVariableName "[ENV VARIABLE]"

# You might need to run this before: Set-ExecutionPolicy Bypass -Scope Process -Force if you are using powershell

# Parameters:
param( [string]$envVariableName, $user_activate = $null )

# Function to resolve input as a direct path or an environment variable
function Resolve-PathOrEnv {
    param ( [string]$envVarOrFullPath )

    if ($envVarOrFullPath -and (Test-Path -Path $envVarOrFullPath)) {
        $inputFileReolved = "$envVarOrFullPath\php.ini"
    } else {
        $resolvedPath = [System.Environment]::GetEnvironmentVariable($envVarOrFullPath, [System.EnvironmentVariableTarget]::Machine)
        if ($resolvedPath -and (Test-Path -Path $resolvedPath)) {
            $inputFileReolved = "$resolvedPath\php.ini"
        } else {
            Write-Host "Provide a valide environment variable or full path for a php directory !" -BackgroundColor "DarkYellow"
            exit(0)
        }
    }

    $backupFile = "$inputFileReolved.bak"
    if (-not (Test-Path $backupFile)) {
        Copy-Item -Path $inputFileReolved -Destination $backupFile        
    }
    return $inputFileReolved
}

$phpIniPath = Resolve-PathOrEnv -envVarOrFullPath $envVariableName

# Read the php.ini file content
$fileContent = Get-Content -Path $phpIniPath

# Initialize variables
$inXdebugSection = $false
$activate = $false

# Determine if we need to comment or uncomment
foreach ($line in $fileContent) {
    if ($line -match "\[xdebug\]") {
        if ($line -match "^;\s*\[xdebug\]") {
            $activate = $true
        } else {
            $activate = $false
        }
        break
    }
}

if ($user_activate) {
    $user_activate = [bool][int]$user_activate
    if ($activate -eq $user_activate) {
        $msg = If ($user_activate) { "activate" } Else { "deactivate" }
        Write-Host "Process started to $msg ..."
    } else {
        $msg = If ($user_activate) { "activated" } Else { "deactivated" }
        Write-Host " xdebug is already $msg " -BackgroundColor DarkYellow
        exit
    }
}

# Create a new list to store the modified content
$newContent = @()

# Process each line in the php.ini file
foreach ($line in $fileContent) {
    if ($line -match "\[xdebug\]") {
        $inXdebugSection = $true
        $modifiedLine = If ($activate) { $line -replace "^;\s*", ""} Else { "; $line" }
    } elseif ($inXdebugSection -and ($line -match "^\[.*\]")) {
        $inXdebugSection = $false
        $modifiedLine = $line
    } elseif ($inXdebugSection) {
        $modifiedLine = If ($activate) { $line -replace "^;\s*", "" } Else { "; $line" }
    } else {
        $modifiedLine = $line
    }
    $newContent += $modifiedLine
}

# Write the modified content back to the php.ini file
$newContent | Set-Content -Path $phpIniPath

If ($activate) {
    $msg = "activated"
    $color = "DarkGreen"
} Else {
    $msg = "deactivated"
    $color = "DarkYellow"
}

Write-Host " xdebug has been $msg " -BackgroundColor $color

