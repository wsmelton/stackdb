function Get-SEArchive {
	<#
	.SYNOPSIS
		Downloads the specified 7-Zip file for the site specified
	.DESCRIPTION
		Downloads the Archive of the specified StackExchange network site
	.PARAMETER SiteName
		String. The [siteName].stackexchange.com; with meta sites you can reference them as "meta.dba".
	.PARAMETER ListAvailable
		Switch to just list the sites found available to download, filters when siteName provided.
    .PARAMETER DownloadPath
        String. The path to download the archive file to on your local or network directory
	.PARAMETER IncludeMeta
		Switch to download meta site along with parent.
	.PARAMETER Force
		Switch to have download path auto created if it does not already exists.
	.EXAMPLE
		Get-SEArchive -SiteName skeptics -DownloadPath 'C:\temp\MyDumpSite'
		Download skeptics site data dump in StackExchange network
	.EXAMPLE
		Get-SEArchive -SiteName skeptics.meta -DownloadPath 'C:\temp\MyDumpSite'
		Download skeptics meta data dump in StackExchange network
	.EXAMPLE
		Get-SEArchive -SiteName woodworking -ListAvailable
		Get list of files for given site that are available, includes date and size
#>
	[CmdletBinding(DefaultParameterSetName="Default")]
	param (
		[ValidateNotNull()]
		[string]$SiteName,
		[ValidateNotNull()]
		[switch]$ListAvailable,
		[Parameter(ParameterSetName="Download")]
		[string]$DownloadPath,
		[Parameter(ParameterSetName="Download")]
		[switch]$IncludeMeta,
		[Parameter(ParameterSetName="Download")]
		[switch]$Force
	)
	[string]$SEArchiveUrl = 'https://archive.org/download/stackexchange'
	Write-Verbose "SE Archive URL: $SEArchiveUrl"
	try {
		$site = Invoke-WebRequest -Uri $SEArchiveUrl
		$siteDumpList = ($site.Links | Where-Object innerHtml -match "7z").innerText
		Write-Verbose "Total number of files found on SE Archive: $($siteDumpList.Count)"
	}
	catch {
		throw "Error`: $_"
	}

	if ($ListAvailable -and (-not $DownloadPath)) {
		<# Attempt to convert file list into usable table output #>
		$result = $site.AllElements | Where-Object tagName -eq "body" | Select-Object -ExpandProperty innerText
		$toHash = $result.Split("`r") | ConvertFrom-String | Where-Object P2 -match "7z"

		$siteList = $toHash | Select-Object @{L ="SiteName"; E= {$_.P2}}, @{L="DatePublished"; E= {$_.P3 + $_.P4}},
		@{L="FileSize"; E= {$_.P5}}
		if ($SiteName) {
			$sitelist = $siteList | Where-Object SiteName -match $SiteName
		}
		return $siteList
	}

	# provide option to create path if it does not exist
	if ( !(Test-Path $DownloadPath -PathType Container) -and $Force ) {
		Write-Verbose "Creating Path: $DownloadPath"
		try {
			$result = New-Item $DownloadPath -ItemType Directory -Force
			if ($result) {
				Write-Output "$($result.FullName) created."
			}
		}
		catch {
			throw "Error`: $_"
		}
	}

	$SiteToGrab = $siteDumpList | Where-Object {$_ -match "^$SiteName"}
	if (-not $IncludeMeta) {
		$SiteToGrab = $SiteToGrab | Where-Object {$_ -notmatch "meta"}
	}
	foreach ($item in $SiteToGrab) {
		try {
			$source = "$SEArchiveUrl/$item"
			$destination = "$DownloadPath\$($item.Split("/")[-1])"
			Write-Verbose "Source path: $source"
			Write-Verbose "Destination path: $destination"

			Write-Output "Downloading $source to $destination"
			(New-Object System.Net.WebClient).DownloadFile($source, $destination)
		}
		catch {
			throw "Error`: $_"
		}
	}
}