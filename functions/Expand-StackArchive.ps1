function Expand-StackArchive {
    <#
        .SYNOPSIS
            Uses 7-Zip to list and extract a zipped file with extension *.7z

        .DESCRIPTION
            Utilizes alias "sz" created within the module StackExchange that calls CLI of 7-Zip
            The path to 7zip program executable is set in the module config (Get-StackdbConfig)

        .PARAMETER ExportPath
            Destination for expanding contents of 7z file.

        .PARAMETER FileName
            The zipped file to be uncompressed.

        .PARAMETER List
            Will list the contents of the zipped file

        .EXAMPLE
            Expand-StackArchive -FileName 'C:\Temp\MyZippedFile.7z' -List

            List contents of the MyZippedFile.7z file
        .EXAMPLE
            Expand-StackArchive -FileName 'C:\Temp\MyZippedFIle.7z' -exportPath 'C:\Temp\MyFolder'

            Export contents of MyZippedFile.7z to C:\Temp\MyFolder
    #>
    [CmdletBinding()]
    param (
        [string]$FileName,
        [string]$ExportPath,
        [switch]$List
    )
    begin {
        if (Test-Path $7zPath) {
            Set-Alias szStackdb $7zPath -Scope Local
        }
        else {
            Stop-PSFFunction -Message "7-zip executable not found"
            return
        }
        if (Test-PSFParameterBinding 'ExportPath' -Not) {
            $ExportPath = (Get-ChildItem $FileName).DirectoryName
        }
    }
    process {
        if (Test-Path $FileName) {
            if ($List) {
                szStackdb l $FileName
            }
            else {
                $baseFileName = (Get-ChildItem $FileName).BaseName.TrimEnd(".7z")
                $ExportPath = $ExportPath + "\" + $baseFileName
                Write-PSFMessage -Level Verbose -Message "Extracting contents to $FileName"
                $execute = "szStackdb e $FileName -aoa -bb0 -o$ExportPath"
                Write-PSFMessage -Level Debug -Message "Invoking: $execute"
                Write-PSFMessage -Level Verbose -Message "Extracting $FileName"
                Invoke-Expression $execute
            }
        }
        else {
            Stop-PSFFunction -Message "[$FileName] File not found"
        }
        Remove-Item alias:\szStackdb -force
    }
}