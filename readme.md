# This is a list of powershell scripts I use on a daily basis


## Common commands
### Services

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\common\services.ps1 list
```

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\common\services.ps1 status
```

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\common\services.ps1 start docker mysql
```

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\common\services.ps1 stop valet
```

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\common\services.ps1 restart valet
```

### Set environment variables
```powershell
powershell -ExecutionPolicy Bypass -File src\commands\common\set-env.ps1 -variableName PATH -variableValue "C:\\my\\bin"
```

### Create empty file

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\common\touch.ps1 src\foo\bar.txt
```

## Docker commands

### Docker infrastructure

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\docker\docker-start-infra.ps1 start
```

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\docker\docker-start-infra.ps1 restart
```

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\docker\docker-start-infra.ps1 status api infrastructure
```

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\docker\docker-start-infra.ps1 stop infrastructure
```

### Setup Laravel PHP in docker

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\docker\setup-php-docker.ps1
```

### Switch Laravel environment
```powershell
powershell -ExecutionPolicy Bypass -File src\commands\docker\switch-env.ps1 -env docker
```

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\docker\switch-env.ps1 -env local
```

## Git commands

### Git commit with custom date

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\git\commit-date.ps1 -date 2025-01-01T12:00:00 -message "Backdate commit"
```

### Git count files

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\git\git-files.ps1 -limit 5
```

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\git\git-files.ps1 -limit 10 -commitHashLimit 8
```

### Git push branches to remotes

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\git\push-all.ps1 -Branches master,staging -Remotes origin,github
```

### Git push to remote

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\git\push-to-remote.ps1 -GitHubToken MYTOKEN -RepoName my-repo -withAllBranches 1
```

## Powershell commands

### Format powershell code

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\powershell\format.ps1
```

```powershell
powershell -ExecutionPolicy Bypass -File src\commands\powershell\format.ps1 src
```


## Directory structure

```sh
src\commands
├── common
│   ├── services.ps1                # Start/Stop/Restart/Status services
│   ├── set-env.ps1                 # Set environment variable
│   └── touch.ps1                   # Create empty file
├── docker
│   ├── docker-start-infra.ps1      # Start docker containers
│   ├── setup-php-docker.ps1        # Setup Laravel PHP in docker
│   └── switch-env.ps1              # Switch laravel environment
├── git
│   ├── commit-date.ps1             # Set commit date
│   ├── git-files.ps1               # Count files in commit
│   ├── push-all.ps1                # Push all changes
│   └── push-to-remote.ps1          # Push current branch to remote
└── powershell
    └── format.ps1                  # Format powershell code
```