# constants
if (Test-Path C:\temp\constants.ps1) {
    Write-Verbose "C:\temp\constants.ps1 found."
    . C:\temp\constants.ps1
}
elseif (Test-Path "$PSScriptRoot\constants.local.ps1") {
    Write-Verbose "tests\constants.local.ps1 found."
    . "$PSScriptRoot\constants.local.ps1"
}
else {
    $script:instance1 = "localhost,1417"
    $script:instance2 = "localhost,1416"
    $script:instance3 = "localhost,1414"
    $script:targetPath = 'C:\sqlfiles'
}