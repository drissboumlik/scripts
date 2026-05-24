# To run this script:
# powershell -ExecutionPolicy Bypass -File "path\to\script\update-branches.ps1" -Branches master,staging -Remotes origin,github

# You might need to run this before: Set-ExecutionPolicy Bypass -Scope Process -Force if you are using powershell

param (
    [string]$Branches, # A single string of branches separated by commas (master,staging)
    [string]$Remotes  # A single string of remotes separated by commas (origin,github)
)

# Get the current branch
$CurrentBranch = (git branch --show-current).Trim()
if (-not $CurrentBranch) {
    Write-Host "Error: Unable to determine the current branch." -ForegroundColor DarkYellow
    exit 1
}

# Split the branches string into an array
$BranchArray = $Branches -split ","
# Split the remote string into an array
$RemoteArray = $Remotes -split ","

# Check if the branches parameter is provided
if (-not $BranchArray -or $BranchArray.Count -eq 0) {
    Write-Host "Error: Please provide at least one branch to merge into." -ForegroundColor DarkYellow
    exit 1
}

function Push-To-Remote {
    param (
        $branch,
        $RemoteArray
    )
    
    foreach ($remote in $RemoteArray) {
        git push $remote $branch
    }
}

# Push the current branch
Write-Host "Pushing the current branch '$CurrentBranch' to remote..." -ForegroundColor Cyan
Push-To-Remote -branch $CurrentBranch -RemoteArray $RemoteArray

# Iterate over the list of branches
foreach ($branch in $BranchArray) {
    if ($branch -eq $CurrentBranch) {
        Write-Host "`nSkipping the current branch '$CurrentBranch'." -ForegroundColor DarkYellow
        continue
    }
    
    Write-Host "`nChecking out branch '$branch'..." -ForegroundColor Cyan
    git checkout $branch

    Write-Host "Merging '$CurrentBranch' into '$branch'..." -ForegroundColor Cyan
    git merge $CurrentBranch

    Write-Host "Pushing branch '$branch' to remote..." -ForegroundColor Cyan
    Push-To-Remote -branch $branch -RemoteArray $RemoteArray
}

# Switch back to the original branch
Write-Host "`nSwitching back to the original branch '$CurrentBranch'..." -ForegroundColor Cyan
git checkout $CurrentBranch

Write-Host "Operation completed successfully!" -ForegroundColor DarkGreen
