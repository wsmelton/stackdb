# Add all things you want to run after importing the main code

# Load Configurations
foreach ($file in (Get-ChildItem "$StackDbRoot\internal\configurations\*.ps1") ) {
    . Import-StackDbFile -FilePath $file.FullName
}

<# load app configs #>
$script:7zPath = Get-StackdbConfigValue -Name app.7zipPath