function Expand-StackArchive {
	<#
	.SYNOPSIS
		Uses 7-Zip to list and extract a zipped file with extension *.7z
	.DESCRIPTION
		Utilizes alias "sz" created within the module StackExchange that calls CLI of 7-Zip
	.PARAMETER 7zPath
		Path to the 7z.exe from 7-Zip, defaults to the ProfileFiles environment variable path
	.PARAMETER ExportPath
		Destination for expanding contents of 7z file.
	.PARAMETER FileName
		The zipped file to be uncompressed.
	.PARAMETER List
		Will list the contents of the zipped file
	.EXAMPLE
	List contents of the MyZippedFile.7z file
    Expand-StackArchive -FileName 'C:\Temp\MyZippedFile.7z' -List
	.EXAMPLE
	Export contents of MyZippedFile.7z to C:\Temp\MyFolder
	Expand-StackArchive -FileName 'C:\Temp\MyZippedFIle.7z' -exportPath 'C:\Temp\MyFolder'
#>
	[CmdletBinding()]
	param (
		[string]$7zPath = "$env:ProgramFiles\7-Zip\7z.exe",
		[string]$FileName,
		[string]$ExportPath,
		[switch]$List
	)
	begin {
		if (Test-Path $7zPath) {
			Set-Alias sz $7zPath -Scope Local
		}
		if (!$ExportPath) {
			$ExportPath = (Get-ChildItem $FileName).DirectoryName
		}
	}
	process {
		if (Test-Path $FileName) {
			if ($List) {
				sz l $FileName
			}
			else {
				$baseFileName = (Get-ChildItem $FileName).BaseName.TrimEnd(".7z")
				$ExportPath = $ExportPath + "\" + $baseFileName
				Write-Verbose "Extracting contents to $FileName"
				$execute = "sz e $FileName -aoa -bb0 -o$ExportPath"
				Write-Verbose "Executing: $execute"
				Write-Output "Extracting $FileName"
				Invoke-Expression $execute
			}
		}
		else {
			Write-Verbose "File does not exist: $FileName"
			Return "[$FileName] File not found"
		}
		Remove-Item alias:\sz -force
	}
}