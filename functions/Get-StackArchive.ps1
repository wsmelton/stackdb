function Get-StackArchive {
    <#
	.SYNOPSIS
		Downloads the specified 7-Zip file for the site specified
	.DESCRIPTION
		Downloads the Archive of the specified StackExchange network site
	.PARAMETER SiteName
		String. The [siteName].stackexchange.com; with meta sites you can reference them as "meta.dba".
	.PARAMETER ListSite
		Output the sites.xml content with details on each site data archive.
    .PARAMETER DownloadPath
        String. The path to download the archive file to on your local or network directory
	.PARAMETER IncludeMeta
		Switch to download meta site along with parent.
	.PARAMETER Force
		Switch to have download path auto created if it does not already exists.
	.EXAMPLE
		Get-StackArchive -SiteName skeptics -DownloadPath 'C:\temp\MyDumpSite'
		Download skeptics site data dump in StackExchange network
	.EXAMPLE
		Get-StackArchive -SiteName skeptics.meta -DownloadPath 'C:\temp\MyDumpSite'
		Download skeptics meta data dump in StackExchange network
	.EXAMPLE
		Get-StackArchive -SiteName woodworking -ListSite
		Get site details for woodworking
    #>
    [CmdletBinding()]
    param (
        [ValidateNotNull()]
        [string]$SiteName,
        [ValidateNotNull()]
        [switch]$ListSite,
        [string]$DownloadPath,
        [switch]$IncludeMeta,
        [switch]$Force
    )
    begin {
        [string]$SEArchiveUrl = 'https://archive.org/download/stackexchange'
        [string]$siteXmlUrl = 'https://archive.org/download/stackexchange/Sites.xml'
        Write-PSFMessage -Level Verbose -Message "SE Archive URL: $SEArchiveUrl"
        Write-PSFMessage -Level Verbose -Message "SE Archive URL: $siteXmlUrl"
    }
    process {
        if ( (Test-PSFParameterBinding 'ListSite') -and (Test-PSFParameterBinding 'DownloadPath' -Not) ) {
            try {
				Write-PSFMessage -Level Verbose -Message "Pulling $siteXmlUrl content"
                [xml]$siteXml = (New-Object System.Net.WebClient).DownloadString($siteXmlUrl)
                $siteList = $siteXml.Sites.Row | Select-Object TinyName, Name, LongName, DatabaseName, TotalQuestions, TotalAnswers, TotalUsers, TotalComments, TotalTags, LastPost

				Write-PSFMessage -Level Verbose -Message "Sites found: $($siteList.Count)"
                if ($SiteName) {
                    $siteList = $siteList | Where-Object TinyName -match $SiteName
                }
                return $siteList
            }
            catch {
                Stop-PSFFunction -Message "Issue getting Sites data" -ErrorRecord $_ -Target $siteXmlUrl
            }
        }
        # provide option to create path if it does not exist
        elseif ( (Test-PSFParameterBinding 'DownloadPath') ) {
            if (( !(Test-Path $DownloadPath -PathType Container) ) -and $Force ) {
                Write-Verbose "Creating Path: $DownloadPath"
                try {
                    $result = New-Item $DownloadPath -ItemType Directory -Force
                    if ($result) {
                        Write-PSFMessage -Level Output -Message "$($result.FullName) created."
                    }
                }
                catch {
                    Stop-PSFFunction -Message "Issue creating path" -ErrorRecord $_ -Target $DownloadPath
                }
            }
            if ( Test-Path $DownloadPath ) {
                try {
                    $site = Invoke-WebRequest -Uri $SEArchiveUrl
                    $siteDumpList = ($site.Links | Where-Object innerHtml -match "7z").innerText
                    Write-PSFMessage -Level Verbose -Message "Total number of files found on SE Archive: $($siteDumpList.Count)"
                }
                catch {
                    Stop-PSFFunction -Message "Issue getting content from $SEArchiveURL" -ErrorRecord $_ -Target $SEArchiveURL
                }

                $SiteToGrab = $siteDumpList | Where-Object {$_ -match "^$SiteName"}
                if (Test-PSFParameterBinding 'IncludeMeta' -Not) {
                    $SiteToGrab = $SiteToGrab | Where-Object {$_ -notmatch "meta"}
                }
                foreach ($item in $SiteToGrab) {
                    try {
                        $source = "$SEArchiveUrl/$item"
                        $destination = "$DownloadPath\$($item.Split("/")[-1])"
                        Write-PSFMessage -Level Verbose -Message "Source path: $source"
                        Write-PSFMessage -Level Verbose -Message "Destination path: $destination"

                        Write-PSFMessage -Level Output -Message "Downloading $source to $destination"
                        (New-Object System.Net.WebClient).DownloadFile($source, $destination)
                        Write-PSFMessage -Level Output -Message "Download completed!"
                    }
                    catch {
                        Stop-PSFFunction -Message "Issue downloading site" -ErrorRecord $_ -Target $item -Continue
                    }
                }
            }
        }
    }
}