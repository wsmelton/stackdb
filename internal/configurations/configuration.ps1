<# Module level configurations #>
Set-PSFConfig -Module stackdb -Name app.7zipPath -Value "$env:ProgramFiles\7-Zip\7z.exe" -Initialize -Description "Executable path for 7Zip program"