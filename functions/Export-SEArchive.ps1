function Export-SEArchive {
<#
	.SYNOPSIS
		Uses 7-Zip to list and extract a zipped file with extension *.7z
	.DESCRIPTION
		Utilizes alias "sz" created within the module StackExchange that calls CLI of 7-Zip
	.PARAMETER filename
		The zipped file to be uncompressed.
	.PARAMETER listContents
		Will list the contents of each zipped file
	.EXAMPLE
	Extract single zipped file and list contents
    Export-SEArchive 'C:\Temp\MyZippedFile.7z' -listContents
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