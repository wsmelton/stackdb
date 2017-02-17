function Export-SEArchive {
<#
	.SYNOPSIS
		Uses 7-Zip to list and extract a zipped file with extension *.7z
	.DESCRIPTION
		Utilizes alias "sz" created within the module StackExchange that calls CLI of 7-Zip
	.PARAMETER szPath
		Path to the 7z.exe from 7-Zip, defaults to the ProfileFiles environment variable path
	.PARAMETER filename
		The zipped file to be uncompressed.
	.PARAMETER listContents
		Will list the contents of the zipped file
	.EXAMPLE
	List contents of the MyZippedFile.7z file
    Export-SEArchive -filename 'C:\Temp\MyZippedFile.7z' -listContents
	.EXAMPLE
	Export contents of MyZippedFile.7z to C:\Temp\MyFolder
	Export-SEArchive -filename 'C:\Temp\MyZippedFIle.7z' -exportPath 'C:\Temp\MyFolder'
#>
	[CmdletBinding()]
	param (
		[string]$szPath = "$env:ProgramFiles\7-Zip\7z.exe",
		[string]$filename,
		[string]$exportPath,
		[switch]$listContents
	)
	BEGIN {
		if (Test-Path $szPath) {
			Set-Alias sz $szPath -Scope Local
		}
		if (!$exportPath) {
			$exportPath = (Get-ChildItem $filename).DirectoryName
		}
	}
	PROCESS {
		if (Test-Path $filename) {
			if ($listContents) {
				sz l $filename
			}
			else {
				Write-Verbose "Extracting contents to $filename"
				$execute = "sz e $filename -o$exportPath"
				Write-Verbose $execute
				Invoke-Expression $execute
			}
		}
		else {
			Write-Verbose "File does not exist: $filename"
			Return "[$filename] File not found"
		}
		Remove-Item alias:\sz -force
	}
}