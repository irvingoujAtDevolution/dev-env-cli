param (
    [string]$Name
)

function Show-Env {
    param (
        [string]$Filter
    )

    function Format-JsonContent {
        param (
            [object]$Content,
            [string]$Indent = ""
        )

        foreach ($property in $Content.PSObject.Properties) {
            if ($property.Value -is [PSCustomObject]) {
                "$Indent$($property.Name) :"
                Format-JsonContent -Content $property.Value -Indent "$Indent    "
            } else {
                "$Indent$($property.Name) : $($property.Value)"
            }
        }
    }

    $jsonFilePath = get_env_path
    $jsonContent = Get-Content -Path $jsonFilePath | ConvertFrom-Json

    if ($Filter) {
        $filteredContent = $jsonContent.PSObject.Properties | Where-Object { $_.Name -like "*$Filter*" }
        foreach ($property in $filteredContent) {
            if ($property.Value -is [PSCustomObject]) {
                "$($property.Name) :"
                Format-JsonContent -Content $property.Value -Indent "    "
            } else {
                "$($property.Name) : $($property.Value)"
            }
        }
    } else {
        Format-JsonContent -Content $jsonContent
    }
}

# Call the Show-Env function
Show-Env -Filter $Name
