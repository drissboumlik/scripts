# To run this script:
# powershell -ExecutionPolicy Bypass -File "path\to\script\git-files.ps1"

# You might need to run this before: Set-ExecutionPolicy Bypass -Scope Process -Force if you are using powershell

param (
    [int]$limit = 10,  # Default limit is 10 commits if no parameter is provided
    [int]$commitHashLimit = 7
)

$counter = 0

git log --numstat --pretty=format:"%H|%s" | ForEach-Object {
    
    if ($counter -ge $limit) { return }  # Stop processing if the limit is reached
    
    if ($_ -match "^[a-f0-9]{7,40}\|") {
        # If a commit hash is found, print the previous commit's results
        if ($commitHash) {
            Write-Output "$commitHash | $fileCount files | $commitSubject"
            $counter++
        }
        
        # Parse commit hash and subject
        $parts = $_ -split "\|"
        $fullCommitHash = $parts[0]
        $commitSubject = $parts[1]
        
        # Update commit hash and reset file count
        $commitHashLimit = [Math]::Min($commitHashLimit, $fullCommitHash.Length)
        $commitHash = $fullCommitHash.Substring(0, $commitHashLimit)
        $fileCount = 0
    } elseif ($_ -match "^\d+\t\d+\t") {
        # Increment file count for file changes
        $fileCount++
    }
} 
# Print the last commit's results
if ($commitHash) {
    Write-Output "$commitHash | $fileCount files | $commitSubject"
}
