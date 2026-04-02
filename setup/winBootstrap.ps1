    # winBootstrap.ps1
    # Optional command line parameters
    param(
        [switch]$ListAllPaths,      # Debug command
        
        [switch]$ShowPipInstall,    # Show pip install progress instead of only showing errors
        [switch]$ListPipInstalls,   # Dump pip list when pip install of requirements.txt is complete

        [switch]$ShowConanInstall,  # Show Conan install progress instead of only showing errors
        [switch]$ListConanInstalls  # Dump conan install "*" when Conan install of conanfile.py is complete
    )

    $ErrorActionPreference = "Stop"

    # Reused names
    $RootRelativeBuildDirName = "build"
    $ConanProfileName = "Chatter"

    # Root of project should be a level above where the script runs
    $RepoRootDir = Join-Path -Path $PSScriptRoot -ChildPath "..\" | Get-Item | Select-Object -ExpandProperty FullName
    # Set other paths relative to RepoRootDir
    $VenvDir = Join-Path -Path $RepoRootDir -ChildPath ".venv"
    $BuildDir = Join-Path -Path $RepoRootDir -ChildPath $RootRelativeBuildDirName
    $RequirementsTxtFile = Join-Path -Path $RepoRootDir -ChildPath "setup\requirements.txt"
    $ConanFileDir = $RepoRootDir
    $ConanToolChainFile = Join-Path -Path $BuildDir -ChildPath "conan_toolchain.cmake"

    if ($ListAllPaths){
        Write-Host "RepoRootDir: $RepoRootDir"
        Write-Host "VenvDir: $VenvDir"
        Write-Host "BuildDir: $BuildDir"
        Write-Host "RequirementsTxtFile: $RequirementsTxtFile"
        Write-Host "ConanFileDir: $ConanFileDir"
        Write-Host "ConanToolChainFile: $ConanToolChainFile"
        Write-Host "--- Only Printing for Debug. Exiting. ---"
        exit 0
    }


    Write-Host "--- Chatter Bootstrap ---"

    # Check if already running venv
    # Activate one if not
    if (-not (Test-Path -Path Env:VIRTUAL_ENV)) {
        # Check for Python
        if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
            Write-Error "python is required but not found"
            exit 1
        } else {
            Write-Host "Found python..."
        }

        # Check for CMake
        if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
            Write-Error "cmake is required but not found"
            exit 1
        } else {
            Write-Host "Found cmake..."
        }

        # Create venv if needed
        if (-not (Test-Path -Path $VenvDir)) {
            Write-Host "Creating virtual environment..."
            python -m venv $VenvDir
        }
        
        # Activate venv
        Write-Host "Activating venv..."
        & "$VenvDir\Scripts\Activate.ps1"
    }

    # Verify pip is available
    if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
        Write-Error "pip is required in venv but not found"
    } else {
        Write-Host "Found pip..."
    }

    # Verify requirements.txt file exists
    if (-not (Test-Path -Path $RequirementsTxtFile)) {
        Write-Error "requirements.txt missing!"
    }

    # Install dependencies from requirements.txt in venv
    # Scope pip install to allow errors so it can complete and we can capture logs
    Write-Host "Installing dependencies..."
    $pipInstallOutput = & {
        $ErrorActionPreference = "Continue"
        pip install -r $RequirementsTxtFile 2>&1
    }

    # Check if pip install was successful
    if ($LASTEXITCODE -ne 0) {
        # Log full output if there was a failure
        $pipInstallOutput | Out-String | Write-Host -ForegroundColor Red
        Write-Error "pip install failed with exit code $LASTEXITCODE"
    } else {
        # Only log successful pip output if requested
        if ($ShowPipInstall) { 
            $pipInstallOutput | Out-String | Write-Host -ForegroundColor Gray
        }

        Write-Host "Installation successful!" -ForegroundColor Green

        # Only log current pip installs if requested
        if ($ListPipInstalls) {
            Write-Host "Current installs:"
            pip list
            Write-Host ""
        }
    }

    # Generate conan profile (Chatter) if setting up for the first time
    $ConanProfile = "$env:USERPROFILE\.conan2\profiles\$ConanProfileName"
    if (-not (Test-Path -Path $ConanProfile)) {
        Write-Host ""
        Write-Host "Creating Conan profile named: $ConanProfileName..."
        conan profile detect --name $ConanProfileName
    } else {
        Write-Host "Conan profile named $ConanProfileName already found and will be used."
    }

    # Create build dir if it doesn't exist
    New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
    if (-not (Test-Path -Path $BuildDir)) {
        Write-Error "Could not create build folder at $BuildDir"
    }

    # Run conan install
    # Scope conan install to allow errors so it can complete and we can capture logs
    Write-Host "Running conan install..."
    $conanInstallOutput = & {
        $ErrorActionPreference = "Continue"
        conan install $ConanFileDir `
        --profile=$ConanProfileName `
        --output-folder="$BuildDir" `
        --build=missing `
        --settings=build_type=Release *>&1
    }

    # Check if conan install was successful
    if ($LASTEXITCODE -ne 0) {
        # Log full output if there was a failure
        $conanInstallOutput | Out-String | Write-Host -ForegroundColor Red
        Write-Error "Conan install failed with exit code $LASTEXITCODE"
    } else {
        # Only log successful conan output if requested
        if ($ShowConanInstall) { 
            $conanInstallOutput | Out-String | Write-Host -ForegroundColor Gray
        }

        Write-Host "Conan install successful!" -ForegroundColor Green

        # Only log current conan installs if requested
        if ($ListConanInstalls) {
            Write-Host "Current conan installs:"
            conan list "*"
            Write-Host ""
        }
    }

    Write-Host "Setup complete for Release config!" -ForegroundColor Green
    Write-Host "To build, make sure venv is still active and then run these commands at the root of your project:" -ForegroundColor Cyan
    Write-Host "  cmake -B $BuildDir -DCMAKE_TOOLCHAIN_FILE=$ConanToolChainFile" -ForegroundColor Cyan
    Write-Host "  cmake --build $BuildDir" -ForegroundColor Cyan