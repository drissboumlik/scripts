param (
    [ValidateSet("docker", "local")]
    [string]$env
)

$currentDir = $PWD.Path

switch ($env) {
    "docker" {
        Copy-Item "$currentDir\.docker\app\.docker.env" "$currentDir\.env" -Force
        Copy-Item "$currentDir\.docker\app\.docker.testing.env" "$currentDir\.env.testing" -Force

        Write-Host "Switched to Docker environment"
    }

    "local" {
        Copy-Item "$currentDir\.local.env" "$currentDir\.env" -Force
        Copy-Item "$currentDir\.local.testing.env" "$currentDir\.env.testing" -Force

        Write-Host "Switched to Local environment"
    }
}