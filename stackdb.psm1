$script:StackDbRoot = $PSScriptRoot

function Import-StackDbFile {
    [cmdletbinding()]
    param (
        [string]$FilePath
    )
    if ($DoDotSource) {
        . $FilePath
    }
    else {
        $ExecutionContext.InvokeCommand.InvokeScript($false,([ScriptBlock]::Create([io.file]::ReadAllText($FilePath))), $null, $null)
    }
}

#region DoDotSource
<# Detect if dot sourcing is enforced #>
$script:DoDotSource = $false
if ($stackdb_DotSourceModule) {
    $script:DoDotSource = $true
}
if ( (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\stackdb\System" -Name "DoDotSource" -ErrorAction Ignore).DoDotSource) {
    $script:DoDotSource = $true
}
#endregion DoDotSource

# Execute Preimport actions
# . Import-StackDbFile -FilePath "$StackDbRoot\internal\scripts\preimport.ps1"

# Import all internal functions
# foreach ($function in (Get-ChildItem "$StackDbRoot\internal\functions\*.ps1")) {
#     . Import-StackDbFile -FilePath $function.FullName
# }

# Import all public functions
foreach ($function in (Get-ChildItem "$StackDbRoot\functions\*.ps1")) {
    $file = $function.FullName
    . Import-StackDbFile -FilePath $file
}

# Execute Postimport actions
. Import-StackDbFile -FilePath "$StackDbRoot\internal\scripts\postimport.ps1"
