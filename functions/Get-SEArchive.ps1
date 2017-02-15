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
	.EXAMPLE
	Download a non-meta site in StackExchange network
    Get-StackExchangeArchive -siteName skeptics -downloadPath 'C:\temp\MyDumpSite'
	.EXAMPLE
	Download a meta site in StachExchange network
	Get-StackExchangeArchive -siteName meta.ell -downloadPath 'C:\temp\MyDumpSite'
	.EXAMPLE
	Download a site and the readme file for StackExchanage Archives
	Get-StackExchangeArchive -siteName dba -downloadPath 'C:\Temp\MyDumpSite' -getReadme
#>
	[CmdletBinding()]
	param (
		[Parameter(
			Mandatory = $true,
			Position = 0
		)]
		[ValidateNotNull()]
		[Alias("site")]
		[string[]]$siteName,
		
		[Parameter(
			Mandatory = $true,
			Position = 1
		)]
		[ValidateNotNull()]
		[string]$downloadPath,
		
		[Parameter(
			Mandatory = $false,
			Position = 2)]
		[switch]$getReadme
	)
	
	# provide option to create path if it does not exist
	if ( !(Test-Path $downloadPath -PathType Container) ) {
		Write-Verbose "Path: $downloadPath == DOES NOT EXIST"
		$decision = Read-Host "Do you want to create $downloadPath (Y/N)?: "
		if ($decision -eq 'Y') {
			try { New-Item $downloadPath -ItemType Directory -Force }
			catch { $errText = $error[0].ToString(); $errText }
		}
	}
	
	Write-Verbose "URL being used: $SEArchiveSite"
	try {
		$siteDumpList = Invoke-WebRequest $SEArchiveSite | Select-Object -ExpandProperty Links | Where-Object { $_ -match ".7z" } | Select-Object -ExpandProperty innerText
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
	
	if ($getReadme) {
		Write-Verbose "Downloading ReadMe.txt"
		$readme = Invoke-WebRequest $SEArchiveSite | Select-Object -ExpandProperty Links | Where-Object { $_ -eq "readme.txt" } | Select-Object -ExpandProperty innerText
		$source = "$SEarchiveSite/$readme"
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

    if ($siteName -match "stackoverflow")
    {
        $decision = Read-Host -Prompt "Are you sure you want to download those big, freaking files???? Y/N"
        if ($decision -eq 'Y') {
            Write-Verbose "Alright you asked for it..."
            
            $Badges = "$SEArchiveSite/stackoverflow.com-Badges.7z"
            $Comments = "$SEArchiveSite/stackoverflow.com-Comments.7z"
            $PostHistory = "$SEArchiveSite/stackoverflow.com-PostHistory.7z"
            $PostLinks = "$SEArchiveSite/stackoverflow.com-PostLinks.7z"
            $Posts = "$SEArchiveSite/stackoverflow.com-Posts.7z"
            $Tags = "$SEArchiveSite/stackoverflow.com-Tags.7z"
            $Users = "$SEArchiveSite/stackoverflow.com-Users.7z"
            $Votes = "$SEArchiveSite/stackoverflow.com-Votes.7z"

		    $destBadges = "$downloadPath\stackoverflow.com-Badges.7z"
            $destComments = "$downloadPath\stackoverflow.com-Comments.7z"
            $destPostHistory = "$downloadPath\stackoverflow.com-PostHistory.7z"
            $destPostLinks = "$downloadPath\stackoverflow.com-PostLinks.7z"
            $destPosts = "$downloadPath\stackoverflow.com-Posts.7z"
            $destTags = "$downloadPath\stackoverflow.com-Tags.7z"
            $destUsers = "$downloadPath\stackoverflow.com-Users.7z"
            $destVotes = "$downloadPath\stackoverflow.com-Votes.7z"

		    try {
		        Write-Verbose "Destination path: $destBadges"
		        Write-Verbose "Source path: $Badges"
			    Invoke-WebRequest $Badges -OutFile $destBadges
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
			try {
		        Write-Verbose "Destination path: $destComments"
                Write-Verbose "Source path: $Comments"
                Invoke-WebRequest $Comments -OutFile $destComments
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
			try {
  		        Write-Verbose "Destination path: $destPostHistory"
                Write-Verbose "Source path: $PostHistory"
                Invoke-WebRequest $PostHistory -OutFile $destPostHistory
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
			try {
                Write-Verbose "Destination path: $destPostLinks"
                Write-Verbose "Source path: $PostLinks"
                Invoke-WebRequest $PostLinks -OutFile $destPostLinks
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
			try {
				Write-Verbose "Destination path: $destPosts"
		        Write-Verbose "Source path: $Posts"
			    Invoke-WebRequest $Posts -OutFile $destPosts
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
			try {
		        Write-Verbose "Destination path: $destTags"
		        Write-Verbose "Source path: $Tags"
			    Invoke-WebRequest $Tags -OutFile $destTags
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
			try {
		        Write-Verbose "Destination path: $destUsers"
		        Write-Verbose "Source path: $Users"
			    Invoke-WebRequest $Users -OutFile $destUsers
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
			try {
		        Write-Verbose "Destination path: $destVotes"
		        Write-Verbose "Source path: $Votes"
			    Invoke-WebRequest $Votes -OutFile $destVotes
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
        }
        else {
            Write-Verbose "Cancelling"
        }
    }
    else {
	    $SiteToGrab = $siteDumpList | Where-Object {$_ -match "^$siteName"}
	    Write-Verbose "Number of site(s) found: $($SiteToGrab.Count)"
	    if ($SiteToGrab.Count -eq 1) {
		    Write-Verbose "Your siteName has been found: $SiteToGrab"
		
		    $source = "$SEArchiveSite/$SiteToGrab"
		    $destination = "$downloadPath\$SiteToGrab"
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
	    elseif ($SiteToGrab.Count -gt 1) {
		    Write-Verbose "More than one file was found"
		    $decision = Read-Host "Do you want to download all files Y/N?"
		    if ($decision -eq 'Y') {
			    foreach ($s in $SiteToGrab) {
				    Write-Verbose "Your siteName has been found: $s"
				    $source = "$SEArchiveSite/$s"
				    $destination = "$downloadPath\$s"

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
		    }
		    elseif ($decision -eq 'N') {
			    Write-Verbose "Cancelling"
		    }
		    else {
			    Write-Verbose "Response was not recognized"
		    }
	    }
    }
}