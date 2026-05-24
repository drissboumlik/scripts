param ($operation)

$directory = (Get-Location).Path
$sub_directories = $args

if (-not $directory -or -not $operation) {
    Write-Host "`nUsage: dcwalk <start|stop|restart|status>"
    exit 1
}

if (-not (Test-Path -Path $directory)) {
    Write-Host "`nDirectory '$directory' does not exist." -ForegroundColor DarkYellow
    exit 1
}

if ($operation -notin @('start', 'stop', 'restart', 'status')) {
    Write-Host "`nInvalid operation '$operation'. Use 'status', 'start', 'stop', or 'restart'." -ForegroundColor DarkYellow
    exit 1
}

$dirs = Get-ChildItem -Path $directory -Directory | Where-Object { -not ($_.Name.StartsWith('.')) }

if ($sub_directories) {
    $sub_directories = $sub_directories | ForEach-Object { $_.TrimEnd('\') }
    $dirs = $dirs | Where-Object {
        if ($sub_directories -contains $_.Name) {
            return $true
        }
        return $false
    }
}

if ($dirs.Length -eq 0) {
    Write-Host "`nNo directories found in '$directory' to process" -ForegroundColor DarkYellow
    exit 0    
}

$dirs = $dirs | Sort-Object {
    if ($_.Name -eq "infrastructure") {
        if ($operation -eq "start") {
            return -1 # top
        } if ($operation -eq "stop") {
            return 1 # bottom
        }
    } else {
        return 0  # leave others unchanged
    }
}

Write-Host "`nDirectories to process in '$directory':" -ForegroundColor Green
$dirs | ForEach-Object { Write-Host " - $($_.Name)" }

if (-not $dirs) {
    Write-Host "`nNo subdirectories found in this directory." -ForegroundColor DarkYellow
    exit 1
}

$dirs | ForEach-Object {
    if (-not (Test-Path -Path "$($_.FullName)\docker-compose.yml")) {
        Write-Host "`nNo docker-compose.yml found in directory '$($_.Name)'. Skipping." -ForegroundColor DarkYellow
        return
    }
    Write-Host "`n`nRunning docker-compose $operation in $($_.Name)`n" -ForegroundColor DarkCyan
    Push-Location $_.FullName
    if ($operation -eq "status") {
        docker-compose ps --status running
    } else {
        docker-compose $operation
    }
    Pop-Location
}
