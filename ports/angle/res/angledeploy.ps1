# Note: This function signature and behavior is depended upon by applocal.ps1

function deployAngle([string]$targetBinaryDir, [string]$installedDir, [string]$targetBinaryName) {
  if ($targetBinaryName -like "libEGL.dll") {
    if(Test-Path "$installedDir\bin\libGLESv2.dll") {
      Write-Verbose "  Deploying libEGL.dll dynamic dependencies"
      deployBinary "$targetBinaryDir" "$installedDir\bin" "libGLESv2.dll"
    }
    if(Test-Path "$installedDir\bin\libGLESv2.pdb") {
      deployBinary "$targetBinaryDir" "$installedDir\bin" "libGLESv2.pdb"
    }

    if(Test-Path "$installedDir\bin\vulkan-1.dll") {
      deployBinary "$targetBinaryDir" "$installedDir\bin" "vulkan-1.dll"
    }
    if(Test-Path "$installedDir\bin\vulkan-1.pdb") {
      deployBinary "$targetBinaryDir" "$installedDir\bin" "vulkan-1.pdb"
    }
  } elseif ($targetBinaryName -like "libGLESv2.dll") {
    if(Test-Path "$installedDir\bin\vulkan-1.dll") {
      Write-Verbose "  Deploying libGLESv2.dll dynamic dependencies"
      deployBinary "$targetBinaryDir" "$installedDir\bin" "vulkan-1.dll"
    }
    if(Test-Path "$installedDir\bin\vulkan-1.pdb") {
      deployBinary "$targetBinaryDir" "$installedDir\bin" "vulkan-1.pdb"
    }
  }
}

