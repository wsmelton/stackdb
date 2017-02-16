function Get-SEArchive {
<#
	.SYNOPSIS
		Downloads the specified 7-Zip file for the site specified
	.DESCRIPTION
		Downloads the Archive of the specified StackExchange network site
	.PARAMETER siteName
		String. The [siteName].stackexchange.com; with meta sites you can reference them as "meta.dba".
    .PARAMETER downloadPath
        String. The path to download the archive file to on your local or network directory
    .PARAMETER getReadme
        Switch. Will download the ReadMe.txt file as well.
	.PARAMETER listAvailable
		Switch to just list all the sites found available to download.
	.EXAMPLE
	Download a non-meta site in StackExchange network
    Get-SEArchive -siteName skeptics -downloadPath 'C:\temp\MyDumpSite'
	.EXAMPLE
	Download a meta site in StackExchange network
	Get-SEArchive -siteName meta.ell -downloadPath 'C:\temp\MyDumpSite'
	.EXAMPLE
	Download a site and the readme file for StackExchanage Archives
	Get-SEArchive -siteName dba -downloadPath 'C:\Temp\MyDumpSite' -getReadme
	.EXAMPLE
	Get list of files for given site that are available, includes date and size
	Get-SEArchive -siteName woodworking -listAvailable
#>
	[CmdletBinding()]
	param (
		[ValidateNotNull()]
		[string[]]$siteName,

		[ValidateNotNull()]
		[string]$downloadPath,

		[switch]$getReadme,
		[switch]$listAvailable
	)
	[string]$SEArchiveUrl = 'https://archive.org/download/stackexchange'
	$downloadPath = $downloadPath.TrimEnd("\")
	Write-Verbose "URL being used: $SEArchiveUrl"
	try {
		$site = Invoke-WebRequest -Uri $SEArchiveUrl
		$siteDumpList = ($site.Links | Where-Object innerHtml -match "7z").innerText
	}
	catch {
		$errText = $error[0].ToString()
		if ($errText.Contains("remote server returned an error")) {
			Write-Verbose "Error returned by archive.org"
			Return "Error returned: $errText"
		}
		else {
			Write-Error $errText
		}
	}

	if ($listAvailable) {
		# Best ditch effort to try and pull down list with name, date, and size of file
		$siteList = ($site.AllElements | Where-Object tagName -eq "body" | ForEach-Object innerText).Split("`r") | Where-Object { $_ -match "7z"}
		if ($siteName) {
			$sitelist = $siteList | Where-Object {$_ -match "$siteName"}
		}
		return $siteList
	}

	# provide option to create path if it does not exist
	if ( !(Test-Path $downloadPath -PathType Container) ) {
		Write-Verbose "Path: $downloadPath == DOES NOT EXIST"
		$decision = Read-Host "Do you want to create $downloadPath (Y/N)?: "
		if ($decision -eq 'Y') {
			try { New-Item $downloadPath -ItemType Directory -Force }
			catch { $errText = $error[0].ToString(); $errText }
		}
	}

	if ($getReadme) {
		Write-Verbose "Downloading ReadMe.txt"
		$readme = Invoke-WebRequest "$SEArchiveUrl/$readme"
		$destination = "$downloadPath\$readme"
		Write-Verbose "Source path: $source"
		Write-Verbose "Destination path: $destination"
		try {
			Invoke-WebRequest $source -OutFile $destination
		}
		catch {
			$errText = $error[0].ToString()
			if ($errText.Contains("remote server returned an error")) {
				Write-Verbose "Error returned by archive.org"
				Return "Error returned: $errText"
			}
			else {
				Write-Error $errText
			}
		}
		if (Test-Path $destination) {
			Write-Verbose "Download completed for $destination"
		}
		else {
			Write-Verbose "Something went wrong and the file $destination does not exist"
		}
	}

	Write-Verbose "Number of files found from URL: $($siteDumpList.Count)"

	$SiteToGrab = $siteDumpList | Where-Object {$_ -match "^$siteName"}
	foreach ($item in $SiteToGrab) {
		try {
			$source = "$SEArchiveUrl\$item"
			$destination = "$downloadPath\$($item.Split("/")[-1])"
			Write-Verbose "Source path: $source"
			Write-Verbose "Destination path: $destination"
			Invoke-WebRequest $source -OutFile $destination
		}
		catch {
			Write-Error $_.Exception
		} #end try/catch
	} #end foreach item
}