param([string]$operation)

. $PSScriptRoot\..\imports\functions.ps1

$serviceNames = $args

function Get-Services-List {
    return [ordered]@{
        "docker" = @{
            "actions" = @{
                "start" = @{ action = {
                    Start-Service "com.docker.service" -ErrorAction SilentlyContinue
                    return 0
                }; success = "Docker service started."; failure = "Failed to start Docker service." }
                "stop" = @{ action = {
                    Stop-Service "com.docker.service" -ErrorAction SilentlyContinue
                    return 0
                }; success = "Docker service stopped."; failure = "Failed to stop Docker service." }
                "restart" = @{ action = {
                    Restart-Service "com.docker.service" -ErrorAction SilentlyContinue
                    return 0
                }; success = "Docker service restarted."; failure = "Failed to restart Docker service." }
                "status" = @{ action = {
                    Display-Service-Status -servicesNames @("com.docker.service") -displayedServiceName "Docker"
                    return 0
                }}
            }
        }
        "mysql" = @{
            "actions" = @{
                "start" = @{ action = {
                    Start-Service "MySQL84" -ErrorAction SilentlyContinue
                    return 0
                }; success = "MySQL service started."; failure = "Failed to start MySQL service." }
                "stop" = @{ action = {
                    Stop-Service "MySQL84" -ErrorAction SilentlyContinue
                    return 0
                }; success = "MySQL service stopped."; failure = "Failed to stop MySQL service." }
                "restart" = @{ action = {
                    Restart-Service "MySQL84" -ErrorAction SilentlyContinue
                    return 0
                }; success = "MySQL service restarted."; failure = "Failed to restart MySQL service." }
                "status" = @{ action = {
                    Display-Service-Status -servicesNames @("MySQL84") -displayedServiceName "MySQL"
                    return 0
                }}
            }
        }
        "mariadb" = @{
            "actions" = @{
                "start" = @{ action = {
                    Start-Service "MariaDB" -ErrorAction SilentlyContinue
                    return 0
                }; success = "MariaDB service started."; failure = "Failed to start MariaDB service." }
                "stop" = @{ action = {
                    Stop-Service "MariaDB" -ErrorAction SilentlyContinue
                    return 0
                }; success = "MariaDB service stopped."; failure = "Failed to stop MariaDB service." }
                "restart" = @{ action = {
                    Restart-Service "MariaDB" -ErrorAction SilentlyContinue
                    return 0
                }; success = "MariaDB service restarted."; failure = "Failed to restart MariaDB service." }
                "status" = @{ action = {
                    Display-Service-Status -servicesNames @("MariaDB") -displayedServiceName "MariaDB"
                    return 0
                }}
            }
        }
        "postgres" = @{
            "actions" = @{
                "start" = @{ action = {
                    Start-Service "postgresql-x64-17" -ErrorAction SilentlyContinue
                    return 0
                }; success = "Postgres service started."; failure = "Failed to start Postgres service." }
                "stop" = @{ action = {
                    Stop-Service "postgresql-x64-17" -ErrorAction SilentlyContinue
                    return 0
                }; success = "Postgres service stopped."; failure = "Failed to stop Postgres service." }
                "restart" = @{ action = {
                    Restart-Service "postgresql-x64-17" -ErrorAction SilentlyContinue
                    return 0
                }; success = "Postgres service restarted."; failure = "Failed to restart Postgres service." }
                "status" = @{ action = {
                    Display-Service-Status -servicesNames @("postgresql-x64-17") -displayedServiceName "Postgres"
                    return 0
                }}
            }
        }
        "valet" = @{
            "actions" = @{
                "start" = @{ action = {
                    $exitCode = $services["valet"]["actions"]["default"].action.Invoke()
                    return $exitCode
                }; success = "Valet services started."; failure = "Failed to start Valet services." }
                "stop" = @{ action = {
                    $exitCode = $services["valet"]["actions"]["default"].action.Invoke()
                    return $exitCode
                }; success = "Valet services stopped."; failure = "Failed to stop Valet services." }
                "restart" = @{ action = {
                    $exitCode = $services["valet"]["actions"]["default"].action.Invoke()
                    return $exitCode
                }; success = "Valet services restarted."; failure = "Failed to restart Valet services." }
                "default" = @{ action = {
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
                }}
                "status" = @{ action = {
                    Display-Service-Status -servicesNames $services["valet"]["list"] -displayedServiceName "Valet"
                    return 0
                }}
            }
            "list" = @("valet_phpcgi_xdebug", "valet_phpcgi", "valet_nginx")
        }
        "vmware" = @{
            "actions" = @{
                "start" = @{ action = {
                    $services["vmware"]["list"] | ForEach-Object { Start-Service $_ -ErrorAction SilentlyContinue }
                    return 0
                }; success = "VMware services started."; failure = "Failed to start VMware services." }
                "stop" = @{ action = {
                    $services["vmware"]["list"] | ForEach-Object { Stop-Service $_ -ErrorAction SilentlyContinue }
                    return 0
                }; success = "VMware services stopped."; failure = "Failed to stop VMware services." }
                "restart" = @{ action = {
                    $services["vmware"]["list"] | ForEach-Object { Restart-Service $_ -ErrorAction SilentlyContinue }
                    return 0
                }; success = "VMware services restarted."; failure = "Failed to restart VMware services." }
                "status" = @{ action = {
                    Display-Service-Status -servicesNames $services["vmware"]["list"] -displayedServiceName "VMWare"
                    return 0
                }}
            }
            "list" = @("VMAuthdService", "VmwareAutostartService", "VMnetDHCP", "VMware NAT Service", "VMUSBArbService")
        }
    }
}

function Show-Services {
    Write-Host "`nSupported services:"
    $services.Keys | ForEach-Object { Write-Host " - $_" }
}

function Operations {
    $commonKeys = $null

    foreach ($service in $services.Values) {
        $actionKeys = $service["actions"].Keys
        if ($null -eq $commonKeys) {
            $commonKeys = $actionKeys
        } else {
            $commonKeys = $commonKeys | Where-Object { $actionKeys -contains $_ }
        }
    }
    Write-Host "`nSupported actions:"
    $commonKeys | ForEach-Object { Write-Host " - $_" }
}

function Run-Operation {

    foreach ($serviceName in $serviceNames) {
        $exitCode = & $services[$serviceName]['actions'][$operation].action

        if ($exitCode -eq 0) {
            Write-Host $services[$serviceName]['actions'][$operation].success -ForegroundColor DarkGreen
        } else {
            Write-Host $services[$serviceName]['actions'][$operation].failure -ForegroundColor DarkYellow
        }
    }

    return $exitCode
}

$services = Get-Services-List

if ($operation -eq "") {
    Write-Host "`nUsage: svc [start|stop|restart|status] [service name]"
    Show-Services
    exit 0
}

# Handle list action
if ($operation -eq "list") {
    Show-Services
    exit 0
}

if ($operation -eq "status") {

    if ($null -eq $serviceNames -or $serviceNames.Count -eq 0) {
        $serviceNames = $services.Keys
    }
    Write-Host "`n" -NoNewline
    $exitCode = Run-Operation
    
    exit $exitCode
}

# Validate service
if ($null -eq $serviceNames -or $serviceNames.Count -eq 0) {
    Write-Host "`nProvide a valid service name."
    Show-Services
    exit 1
}

# Validate action for the service
$serviceNames | ForEach-Object {
    if (-not $services.Contains($_)) {
        Write-Host "`nUnknown service: $_"
        Show-Services
        exit 1
    } elseif (-not $services[$_]['actions'].ContainsKey($operation)) {
        Write-Host "`nAction '$operation' not supported for service '$_'"
        Operations
        exit 1
    }
}

# Execute the command
if (Is-Admin) {
    Write-Host "`n" -NoNewline
    $exitCode = Run-Operation
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
            Write-Host $services[$serviceName]['actions'][$operation].success -ForegroundColor DarkGreen
        } else {
            Write-Host $services[$serviceName]['actions'][$operation].failure -ForegroundColor DarkYellow
        }
    }

    exit $exitCode
} catch {
    Write-Host "`nOperation canceled or failed to elevate privileges." -ForegroundColor DarkYellow
    exit 1
}