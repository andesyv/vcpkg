# Note: This function signature and behavior is depended upon by applocal.ps1

function deployAngle([string]$targetBinaryDir, [string]$installedDir, [string]$targetBinaryName) {
    if ($targetBinaryName -like "libEGL.dll") {
        Write-Verbose "  Deploying libEGL.dll dynamic dependencies"
        foreach ($file in @("libGLESv2.dll", "libGLESv2.pdb", "vulkan-1.dll", "vulkan-1.pdb", "third_party_zlib.dll", "third_party_zlib.pdb")) {
            if (Test-Path "$installedDir\bin\$file")
            {
                deployBinary "$targetBinaryDir" "$installedDir\bin" "$file"
            }
        }
    }
}

