


function Is-Admin {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Display-Service-Status {
    param($servicesNames, $displayedServiceName)

    $maxLineLength = 60
    Write-Host "$displayedServiceName services:" -ForegroundColor Cyan
    foreach ($serviceName in $servicesNames) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction Stop
            $color = if ($service.Status -eq 'Running') { 'DarkGreen' } else { 'DarkYellow' }
            $dotsCount = $maxLineLength - $serviceName.Length
            if ($dotsCount -lt 0) { $dotsCount = 0 }

            $dots = '.' * $dotsCount
            Write-Host "- $serviceName $dots " -NoNewline
            Write-Host $service.Status -ForegroundColor $color
        } catch {
            $dots = '.' * ($maxLineLength - $serviceName.Length)
            Write-Host "- $serviceName $dots " -NoNewline
            Write-Host "NOT FOUND" -ForegroundColor Yellow
        }
    }
}

function Display-Output-Message {
    param($exitCode, $operation)

    if ($exitCode -eq 0) {
        $message = $messages[$operation]
        Write-Host "`n$message" -ForegroundColor DarkGreen
    } else {
        Write-Host "`nvalet $operation failed with code $exitCode." -ForegroundColor DarkYellow
    }
}