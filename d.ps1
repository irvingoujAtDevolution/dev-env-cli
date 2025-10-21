param(
    [string]$Command
)

function Build {
    Write-Host "Building project..."
    dotnet build -c Release
}

function Pack {
    Write-Host "Packing project..."
    dotnet pack -c Release
}

function Push {
    # Define the base path where the packages are located
    $basePath = "./bin/Release"
    
    # Get all snupkg files in the base path
    $snupkgFiles = Get-ChildItem -Path $basePath -Filter *.nupkg

    # Extract package names and versions from file names
    $packages = $snupkgFiles | ForEach-Object {
        $fileName = $_.Name
        $nameParts = $fileName -split '\.'
        
        # Assuming the version is in the format year.month.day.minor
        $version = $nameParts[-4..-2] -join '.'  # Combine the year, month, and day
        $minorVersion = $nameParts[-2]           # Capture the minor version part
        $fullVersion = "$version.$minorVersion"  # Combine into full version string
        $packageName = $nameParts[0..($nameParts.Length - 5)] -join '.'
        
        # Return an object with package name, full version, and full path
        [PSCustomObject]@{
            Name = $packageName
            Version = $fullVersion
            Path = $_.FullName
        }
    }

    # Sort the packages by version number and select the latest one
    $latestPackage = $packages | Sort-Object -Property Version -Descending | Select-Object -First 1

    # Write to host about the package being pushed
    Write-Host "Pushing package $($latestPackage.Path) to NuGet server..."

    # Push the latest package to the NuGet server
    dotnet nuget push $latestPackage.Path --source "C:\NuGetServer"
}



switch ($Command) {
    "build" {
        Build
    }
    "pack" {
        Pack
    }
    "push" {
        Push
    }
    "cc" {
        dotnet nuget locals --clear all
    }
    "rm-bin"{
        Remove-Item -Path "./bin" -Recurse -Force
    }
    "rm-nuget"{
        Remove-Item -Path "C:\NuGetServer\*"
    }
    default {
        Write-Host "Unknown command: $Command. Please specify 'build', 'pack','cc (cache clean)','rm-nuget','rm-bin', or 'push'."
    }
}
