param([string]$operation)

. $PSScriptRoot\..\..\helpers\functions.ps1

$serviceNames = $args

function Get-Services-List {
    return [ordered]@{
        "docker" = @{
            "displayName" = "Docker"
            "services" = @("com.docker.service")
        }
        "mysql" = @{
            "displayName" = "MySQL"
            "services" = @("MySQL84")
        }
        "mariadb" = @{
            "displayName" = "MariaDB"
            "services" = @("MariaDB")
        }
        "postgres" = @{
            "displayName" = "Postgres"
            "services" = @("postgresql-x64-17")
        }
        "valet" = @{
            "displayName" = "Valet"
            "services" = @("valet_phpcgi_xdebug", "valet_phpcgi", "valet_nginx")
            "action" = {
                param ($operation)

                # Path to valet.bat
                $valetBat = "$env:APPDATA\Composer\vendor\bin\valet.bat"

                if (-not (Test-Path $valetBat)) {
                    Write-Host "`nOups! Could not find valet.bat at:" -ForegroundColor DarkYellow
                    Write-Host $valetBat
                    exit 1
                }

                # Run valet command
                $startInfo = New-Object System.Diagnostics.ProcessStartInfo
                $startInfo.FileName = $valetBat
                $startInfo.Arguments = $operation
                $startInfo.RedirectStandardOutput = $true
                $startInfo.RedirectStandardError = $true
                $startInfo.UseShellExecute = $false
                $startInfo.CreateNoWindow = $true

                $proc = New-Object System.Diagnostics.Process
                $proc.StartInfo = $startInfo
                $proc.Start() | Out-Null

                $output = $proc.StandardOutput.ReadToEnd()
                $errorOutput = $proc.StandardError.ReadToEnd()
                $proc.WaitForExit()

                return $proc.ExitCode
            }
        }
        "vmware" = @{
            "displayName" = "VMWare"
            "services" = @("VMAuthdService", "VmwareAutostartService", "VMnetDHCP", "VMware NAT Service", "VMUSBArbService")
        }
    }
}

function Show-Services {
    param ($services)
    Write-Host "`nSupported services:"
    $services.Keys | ForEach-Object { Write-Host " - $_" }
}

function Supported-Operations {
    return @("start", "stop", "restart", "status")
}

function Get-Operations {
    Write-Host "`nSupported actions:"
    $supportedOperations = Supported-Operations
    $supportedOperations | ForEach-Object { Write-Host " - $_" }
}

function Run-Operation-On-Service {
    param ($serviceObject, $operation)

    if ($operation -ne "status" -and $null -ne $serviceObject.action) {
        return $serviceObject.action.Invoke($operation)
    }

    $runner = @{
        "start" = {  $serviceObject.services | ForEach-Object { Start-Service $_ -ErrorAction Stop } }
        "stop" = {  $serviceObject.services | ForEach-Object { Stop-Service $_ -ErrorAction Stop } }
        "restart" = {  $serviceObject.services | ForEach-Object { Restart-Service $_ -ErrorAction Stop } }
        "status" = { Display-Service-Status -servicesNames $serviceObject.services -displayedServiceName $serviceObject.displayName }
    }

    $runner[$operation].Invoke()

    return 0
}

function Run-Operation {
    param ($serviceNames, $operation, $services)

    foreach ($serviceName in $serviceNames) {
        $exitCode = 0
        try {
            $exitCode = Run-Operation-On-Service -serviceObject $services[$serviceName] -operation $operation
        } catch {
            $exitCode = 1
        }

        if ($exitCode -eq 0) {
            Write-Host "$($services[$serviceName].displayName) service $operation successfully" -ForegroundColor DarkGreen
        } else {
            Write-Host "$($services[$serviceName].displayName) service $operation failed" -ForegroundColor DarkYellow
        }
    }

    return $exitCode
}

$services = Get-Services-List

if ($operation -eq "") {
    Write-Host "`nUsage: svc [start|stop|restart|status] [service name]"
    Show-Services -services $services
    exit 0
}

# Handle list action
if ($operation -eq "list") {
    Show-Services -services $services
    exit 0
}

if ($operation -eq "status") {

    if ($null -eq $serviceNames -or $serviceNames.Count -eq 0) {
        $serviceNames = $services.Keys
    }

    $matchingServices = $services.Keys | Where-Object { $serviceNames -contains $_ }

    if ($matchingServices.Count -eq 0) {
        Write-Host "`nNo matching services found for the provided names."
        Show-Services -services $services
        exit 1
    }

    Write-Host "`n" -NoNewline

    $serviceNames | ForEach-Object {
        $serviceObject = $services[$_]
        Display-Service-Status -servicesNames $serviceObject.services -displayedServiceName $serviceObject.displayName
        Write-Host "`n" -NoNewline
    }

    exit 0
}

# Validate service
if ($null -eq $serviceNames -or $serviceNames.Count -eq 0) {
    Write-Host "`nProvide a valid service name."
    Show-Services -services $services
    exit 1
}

# Validate action for the service
$serviceNames | ForEach-Object {
    $supportedOperations = Supported-Operations
    if (-not $services.Contains($_)) {
        Write-Host "`nUnknown service: $_"
        Show-Services -services $services
        exit 1
    } elseif (-not $supportedOperations.Contains($operation)) {
        Write-Host "`nAction '$operation' not supported for service '$_'"
        Get-Operations
        exit 1
    }
}

# Execute the command
if (Is-Admin) {
    Write-Host "`n" -NoNewline
    $exitCode = Run-Operation -serviceNames $serviceNames -operation $operation -services $services
    exit $exitCode
}


# Not admin - relaunch as admin
try {
    $arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`" $operation $serviceNames"
    $process = Start-Process powershell -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -PassThru
    $process.WaitForExit()
    $exitCode = $process.ExitCode

    Write-Host "`n" -NoNewline
    foreach ($serviceName in $serviceNames) {
        if ($exitCode -eq 0) {
            Write-Host "$($services[$serviceName].displayName) service $operation successfully" -ForegroundColor DarkGreen
        } else {
            Write-Host "$($services[$serviceName].displayName) service $operation failed" -ForegroundColor DarkYellow
        }
    }

    exit $exitCode
} catch {
    Write-Host "`nOperation canceled or failed to elevate privileges." -ForegroundColor DarkYellow
    exit 1
}