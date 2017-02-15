function Import-SeArchive
{
<#
	.SYNOPSIS
		Pulls XML dump file and bulk loads into database
	.DESCRIPTION
		Imports the XML dump file and then uses bulk load method to import into specified database
	.PARAMETER pathToFiles
		String. The path to where the uncompressed XML files are located for the StackExchange site
    .PARAMETER server
        String. SQL Server instance were database is located
    .PARAMETER database
        String. Database where you want to import the data
    .PARAMETER schema
        String. Defaults to "dbo", specify schema if using specific one
    .PARAMETER tableList
        String array. List of tables to be used to import data, accepts array of values
    .PARAMATER batchSize
        Integer. If you want to set the batch size for the bulk copy process, otherwise it is not set. Good to use if loading StackOverflow site data.
	.EXAMPLE
	Import one table to specific schema
    Import-SeArchive -pathToFiles 'C:\temp\quant.stackexchange.com' -server MANATARMS\SQL12 -database StackExchange -schema quant -tableList Badges
	.EXAMPLE
	Import multiple tables to specific schema
	Import-SeArchive -pathToFiles 'C:\temp\quant.stackexchange.com' -server MANATARMS\SQL12 -database StackExchange -schema quant -tableList 'Badges','Votes'
	.EXAMPLE
	Import all files into database, using default schema, and verbose logging
	$files = Get-ChildItem 'C:\temp\quant.stackexchange.com' -filter *.xml | Select-Object -ExpandProperty BaseName
    Import-SeArchive -pathToFiles 'C:\temp\quant.stackexchange.com' -server MANATARMS\SQL12 -database StackExchange -tableList $files -Verbose
    .EXAMPLE
    Setting the batch size
    Import-SeArchive -pathToFiles 'C:\temp\quant.stackexchange.com' -server MANATARMS\SQL12 -database StackExchange -schema quant -tableList 'Badges','Votes' -batchSize 1000
#>

	[cmdletbinding()]
	param (
		[string]$pathToFiles,
        [string]$server,
        [string]$database,
        [string]$schema = 'dbo',
        [string[]]$tableList,
        [int]$batchSize
	)
	
	if ( !(Test-Path $pathToFiles) ) {
		Write-Error -Message "***The path provided does not exist***"
        Break;
	}
    
    Push-Location
    Set-Location $pathToFiles

    $Files = Get-ChildItem -Path $pathToFiles -Filter *.xml | Select-Object Name, BaseName

    $sqlCn = New-Object System.Data.SqlClient.SqlConnection("Data Source=$($server);Integrated Security=SSPI;Initial Catalog=$($database)");
    try {
        $sqlCn.Open();
        $bulkLoad = New-Object ("System.Data.SqlClient.SqlBulkCopy") $sqlCn
        if ($batchSize -ne $null) { $bulkLoad.BatchSize = $batchSize }
    }
    catch
    {
    	$errText = $error[0].ToString()
    	if ($errText.Contains("Failed to connect")) {
		    Write-Verbose "Connection to $server failed."
		    Return "Connection failed to $server"
	    }
		else {
			Write-Error $errText
			break;
		}
    }

    $totalFiles = $files.Count
    $totalTables = $tableList.Count
    $i=$x = 1
    foreach ($f in $Files) {
        Write-Progress -Id 1 -Activity "Working on Files" -Status "Processing $($f.Name)" -PercentComplete $i
        foreach ($t in $tableList) {
            Write-Progress -Id 2 -Activity "Working on Tables" -Status "Processing $t" -PercentComplete $x
                if (Test-Path $f.Name )
                {
                        if ($t -eq $f.BaseName) {
                            switch ($t) {
                                "Badges" {
                                    Write-Verbose "Found Badges file..."
                                    [xml]$badges = Get-Content $f.Name
                                    $badgesDt = $badges.badges.Row | Select-Object Id, UserId, Name, Date | Out-DataTable
                                    $bulkLoad.DestinationTableName = "$schema.$t"
                                    Write-Verbose "Bulk loading Badges file..."
                                    $bulkLoad.WriteToServer($badgesDt)
                                }
                                "Comments" {  
                                    Write-Verbose "Found Comments file..."
                                    [xml]$comments = Get-Content $f.Name
                                    $commentsDt = $comments.comments.row | Select-Object Id, PostId, Score, Text, CreationDate, UserId | Out-DataTable
                                    $bulkLoad.DestinationTableName = "$schema.$t"
                                    Write-Verbose "Bulk loading Comments file..."
                                    $bulkLoad.WriteToServer($commentsDt)
                                }
                                "PostHistory" {
                                    Write-Verbose "Found PostHistory file..."
                                    [xml]$postHistory = Get-Content $f.Name
                                    $postHistoryDt = $postHistory.posthistory.row | Select-Object Id, PostHistoryTypeId, PostId, RevisionGUID, CreationDate, 
                                        UserId, UserDisplayName, Comment, Text, CloseReasonId | Out-DataTable
                                    $bulkLoad.DestinationTableName = "$schema.$t"
                                    Write-Verbose "Bulk loading PostHistory file..."
                                    $bulkLoad.WriteToServer($postHistoryDt)
                                }
                                "PostLinks" {
                                    Write-Verbose "Found PostLinks file..."
                                    [xml]$postLink = Get-Content $f.Name
                                    $postLinkDt = $postLink.postlinks.row | Select-Object Id, CreationDate, PostId, RelatedPostId, LinkTypeId | Out-DataTable
                                    $bulkLoad.DestinationTableName = "$schema.$t"
                                    Write-Verbose "Bulk loading PostLinks file..."
                                    $bulkLoad.WriteToServer($postLinkDt)
                                }
                                "Posts" {
                                    Write-Verbose "Found Posts file..."
                                    [xml]$posts = Get-Content $f.Name
                                    $postsDt = $posts.posts.row | Select-Object Id, PostTypeId, ParentId, AcceptedAnswerId, CreationDate, Score, ViewCount,
                                        Body, OwnerUserId, LastEditorUserId, LastEditorDisplayName, LastEditDate, LastActivityDate, CommunityOwnedDate,
                                        ClosedDate, Title, Tags, AnswerCount, CommentCount, FavoriteCount | Out-DataTable
                                    $bulkLoad.DestinationTableName = "$schema.$t"
                                    Write-Verbose "Bulk loading Posts file..."
                                    $bulkLoad.WriteToServer($postsDt)
                                }
                                "Tags" {
                                    Write-Verbose "Found Tags file..."
                                    [xml]$tags = Get-Content $f.Name
                                    $tagsDt = $tags.tags.row | Select-Object Id, TagName, Count, ExcerptPostId, WikiPostId | Out-DataTable
                                    $bulkLoad.DestinationTableName = "$schema.$t"
                                    Write-Verbose "Bulk loading Tags file..."
                                    $bulkLoad.WriteToServer($tagsDt)
                                }
                                "Users" {
                                    Write-Verbose "Found Users file..."
                                    [xml]$users = Get-Content $f.Name
                                    $usersDt = $users.users.row | Select-Object Id, Reputation, CreationDate, DisplayName, EmailHash, LastAccessDate, WebsiteUrl,
                                        Location, Age, AboutMe, Views, UpVotes, DownVotes, ProfileImageUrl, AccountId | Out-DataTable
                                    $bulkLoad.DestinationTableName = "$schema.$t"
                                    Write-Verbose "Bulk loading Users file..."
                                    $bulkLoad.WriteToServer($usersDt)
                                }
                                "Votes" {
                                    Write-Verbose "Found Votes file..."
                                    [xml]$votes = Get-Content $f.Name
                                    $votesDt = $votes.votes.row | Select-Object Id, PostId, VoteTypeId, UserId, CreationDate, BountyAmount | Out-DataTable
                                    $bulkLoad.DestinationTableName = "$schema.$t"
                                    Write-Verbose "Bulk loading Votes file..."
                                    $bulkLoad.WriteToServer($votesDt)
                                }
                            }
                        }
                    }
                else {
                    Write-Warning "No valid files found in provided directory"
                }
            $x++
        }
        $i++

    }
    $sqlCn.Close()

    Pop-Location
}