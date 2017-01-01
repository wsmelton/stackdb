function Export-StackExchangeArchive {
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
    Export-StackExchangeArchive 'C:\Temp\MyZippedFile.7z' -listContents
#>
	[CmdletBinding()]
	param (
		[Parameter(
			Mandatory = $true,
			Position = 0
		)]
		[ValidateNotNull()]
		[Alias("file")]
		[string]$filename,
		[Parameter(
			Mandatory = $false,
			Position = 1
		)]
		[switch]$listContents
	)
	
	if (Test-Path $filename) {
		if ($listContents) {
			sz l $filename
			Write-Verbose "Extracting contents of $filename"
			sz e $filename
		}
		else {
			Write-Verbose "Extracting contents to $filename"
			sz e $filename
		}
	}
	else {
		Write-Verbose "File does not exist: $filename"
		Return "File not found"
	}
}