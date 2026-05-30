
# To run this script:
# powershell -ExecutionPolicy Bypass -File "path\to\script\set-env.ps1" -variableName "[ENV VARIABLE]" -variableValue "[DIRECTORY OR ENV VARIABLE]"

# If you have chocolatey installed add the RefreshEnv command to reload the environment variables
# powershell -ExecutionPolicy Bypass -File "path\to\script\set-env.ps1" -variableName "[ENV VARIABLE]" -variableValue "[DIRECTORY OR ENV VARIABLE]" && RefreshEnv.cmd

# You might need to run this before: Set-ExecutionPolicy Bypass -Scope Process -Force if you are using powershell

# Parameters:
param( [string]$variableName, [string]$variableValue )

. $PSScriptRoot\..\..\helpers\functions.ps1

if (-not $variableName -or -not $variableValue) {
	Write-Host "Error: Please provide both a variable name and value." -ForegroundColor DarkYellow
	exit 1
}

try {

	if (Is-Admin) {
		$variableValueContent = [System.Environment]::GetEnvironmentVariable($variableValue, [System.EnvironmentVariableTarget]::Machine)
		if ($variableValueContent) {
			[System.Environment]::SetEnvironmentVariable($variableName, $variableValueContent, [System.EnvironmentVariableTarget]::Machine)
		} else {
			[System.Environment]::SetEnvironmentVariable($variableName, $variableValue, [System.EnvironmentVariableTarget]::Machine)
		}

		if ($exitCode -eq 0) {
			Write-Host "Environment variable '$variableName' set to '$variableValue' at the system level." -ForegroundColor DarkGreen
		} else {
			Write-Host "Failed to set environment variable '$variableName'." -ForegroundColor DarkYellow
		}
		exit $exitCode
	}

	# Relaunch as administrator with hidden window
	$arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -variableName `"$variableName`" -variableValue `"$variableValue`""
	$process = Start-Process powershell -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -PassThru
	$process.WaitForExit()
	$exitCode = $process.ExitCode

	if ($exitCode -eq 0) {
		Write-Host "Environment variable '$variableName' set to '$variableValue' at the system level." -ForegroundColor DarkGreen
	} else {
		Write-Host "Failed to set environment variable '$variableName'." -ForegroundColor DarkYellow
	}
	exit $exitCode
} catch {
	Write-Host "Something went wrong, believe me !!"
	Write-Host "Error: $_" -ForegroundColor DarkYellow
	exit 1
}

