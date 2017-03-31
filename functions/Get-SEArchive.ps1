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
	.PARAMETER listAvailable
		Switch to just list the sites found available to download, filters when siteName provided.
	.EXAMPLE
	Download a non-meta site in StackExchange network
    Get-SEArchive -siteName skeptics -downloadPath 'C:\temp\MyDumpSite'
	.EXAMPLE
	Download a meta site in StackExchange network
	Get-SEArchive -siteName meta.ell -downloadPath 'C:\temp\MyDumpSite'
	.EXAMPLE
	Get list of files for given site that are available, includes date and size
	Get-SEArchive -siteName woodworking -listAvailable
#>
	[CmdletBinding()]
	param (
		[ValidateNotNull()]
		[string]$siteName,
		[ValidateNotNull()]
		[string]$downloadPath,
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
		throw "Error`: $_"
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
			try {
				New-Item $downloadPath -ItemType Directory -Force
			}
			catch {
				throw "Error`: $_"
			}
		}
	}

	Write-Verbose "Number of files found from URL: $($siteDumpList.Count)"

	$SiteToGrab = $siteDumpList | Where-Object {$_ -match "^$siteName"}
	foreach ($item in $SiteToGrab) {
		try {
			$source = "$SEArchiveUrl/$item"
			$destination = "$downloadPath\$($item.Split("/")[-1])"
			Write-Verbose "Source path: $source"
			Write-Verbose "Destination path: $destination"

			(New-Object System.Net.WebClient).DownloadFile($source,$destination)
		}
		catch {
			throw "Error`: $_"
		} #end try/catch
	} #end foreach item
}