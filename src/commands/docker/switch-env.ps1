param (
    [ValidateSet("docker", "local")]
    [string]$env
)

if (-not $env) {
    Write-Host "Error: Please specify an environment to switch to (docker or local)." -ForegroundColor DarkYellow
    exit 1
}

$currentDir = $PWD.Path

switch ($env) {
    "docker" {
        if (-Not (Test-Path "$currentDir\.docker\app\.docker.env")) {
            Write-Host "Error: .docker\app\.docker.env directory not found in current directory." -ForegroundColor DarkYellow
            exit 1
        }
        Copy-Item "$currentDir\.docker\app\.docker.env" "$currentDir\.env" -Force
        Copy-Item "$currentDir\.docker\app\.docker.testing.env" "$currentDir\.env.testing" -Force

        Write-Host "Switched to Docker environment"
    }

    "local" {
        if (-Not (Test-Path "$currentDir\.local.env")) {
            Write-Host "Error: .local directory not found in current directory." -ForegroundColor DarkYellow
            exit 1
        }
        Copy-Item "$currentDir\.local.env" "$currentDir\.env" -Force
        Copy-Item "$currentDir\.local.testing.env" "$currentDir\.env.testing" -Force

        Write-Host "Switched to Local environment"
    }
}