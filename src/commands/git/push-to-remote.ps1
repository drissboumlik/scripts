param (
    [string]$GitHubToken,
    [string]$RepoName,
    [string]$GitHubUsername = "drissboumlik",
    [int]$withAllBranches = 0
)

# GitHub API endpoint
$GitHubApiUrl = "https://api.github.com/user/repos"

# Create a new repository on GitHub via the API
$Headers = @{
    "Authorization" = "token $GitHubToken"
    "User-Agent" = "$GitHubUsername"
}

try {
    $Body = @{
        name = $RepoName
        private = $false
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $GitHubApiUrl -Method Post -Headers $Headers -Body $Body

    # Add GitHub repository as remote
    git remote add origin "https://github.com/$GitHubUsername/$RepoName.git"
}
catch {
    Write-Host "`nError while creating repository" -ForegroundColor DarkYellow
}

Write-Host "`nPushing to remote repository: $RepoName"
# Push to GitHub
if ($withAllBranches) {
    git push --all origin > $null 2>&1
} else {
    git push -u origin master > $null 2>&1
}

Write-Host "`nRepository $RepoName pushed successfully!" -ForegroundColor DarkGreen