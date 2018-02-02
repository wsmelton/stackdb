function Import-StackArchive {
<#
	.SYNOPSIS
		Pulls XML dump file and bulk loads into database
	.DESCRIPTION
		Imports the XML dump file and then uses bulk load method to import into specified database
	.PARAMETER filepath
		The path to where the uncompressed XML files are located for the StackExchange site
    .PARAMETER sqlserver
        SQL Server instance were database is located
    .PARAMETER database
        Database where you want to import the data
    .PARAMETER schema
        Defaults to "dbo", specify schema if using specific one
    .PARAMETER tableList
        If you want to granularly load tables for demos or refresh a table.
    .PARAMETER batchSize
        Set the batch size for the bulk copy process, default to 2000. May want to adjust when loading SO database.
	.EXAMPLE
	Import one table to specific schema
    Import-StackArchive -folder 'C:\temp\quant.stackexchange.com' -server MANATARMS\SQL12 -database StackExchange -schema quant -tableList Badges
	.EXAMPLE
	Import multiple tables to specific schema
	Import-StackArchive -folder 'C:\temp\quant.stackexchange.com' -server MANATARMS\SQL12 -database StackExchange -schema quant -tableList 'Badges','Votes'
	.EXAMPLE
	Import all files into database, using default schema, and verbose logging
	$files = Get-ChildItem 'C:\temp\quant.stackexchange.com' -filter *.xml | Select-Object -ExpandProperty BaseName
    Import-StackArchive -folder 'C:\temp\quant.stackexchange.com' -server MANATARMS\SQL12 -database StackExchange -tableList $files -Verbose
#>

    [cmdletbinding()]
    param (
        [string]$folder,
        [string]$sqlserver,
        [string]$database,
        [string]$schema = 'dbo',
        [string[]]$tableList,
        [int]$batchSize
    )

    if ( !(Test-Path $folder) ) {
        throw "The path provided does not exist!!"
    }
    if ($batchSize -eq 0) {
        $batchSize = 2000
    }
    if ($tableList.Length -eq 0) {
        $tableList = 'Badges','Comments','PostHistory','PostLinks','Posts','Tags','Users','Votes'
    }

#    Push-Location
#    Set-Location $folder

    $fileList = 'Badges.xml','Comments.xml','PostHistory.xml','PostLinks.xml','Posts.xml','Tags.xml','Users.xml','Votes.xml'

    $files = Get-ChildItem -Path $folder | Where-Object Name -in $fileList | Select-Object Name, BaseName

    $sqlcn = New-SqlCn -sqlserver $sqlserver -database $database

    try {
        $bulkLoad = New-Object ("System.Data.SqlClient.SqlBulkCopy") $sqlcn
        $bulkLoad.BatchSize = $batchSize
    }
    catch {
        throw "Error`: $_"
    }

    $totalfiles = $files.Count
    $totalTables = $tableList.Count
    $i=$x = 1
    foreach ($f in $files) {
        Write-Progress -Id 1 -Activity "Working on files" -Status "Processing $($f.Name)" -PercentComplete $i
        foreach ($t in $tableList) {
            Write-Progress -Id 2 -Activity "Working on Tables" -Status "Processing $t" -PercentComplete $x
            if (Test-Path $f.Name ) {
                if ($t -eq $f.BaseName) {
                    switch ($t) {
                        "Badges" {
                            Write-Verbose "Found Badges file..."
                            [xml]$badges = Get-Content $f.Name
                            $badgesDt = $badges.badges.Row | Select-Object UserId, Name, Date | Out-DataTable
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
                            Location, Age, AboutMe, Views, UpVotes, DownVotes | Out-DataTable
                            $bulkLoad.DestinationTableName = "$schema.$t"
                            Write-Verbose "Bulk loading Users file..."
                            $bulkLoad.WriteToServer($usersDt)
                        }
                        "Votes" {
                            Write-Verbose "Found Votes file..."
                            [xml]$votes = Get-Content $f.Name
                            $votesDt = $votes.votes.row | Select-Object Id, PostId, VoteTypeId, CreationDate, UserId, BountyAmount | Out-DataTable
                            $bulkLoad.DestinationTableName = "$schema.$t"
                            Write-Verbose "Bulk loading Votes file..."
                            $bulkLoad.WriteToServer($votesDt)
                        }
                    } #end switch $t
                } #end if test basename
            } #end if test name
            else {
                Write-Warning "No valid files found in provided directory"
            }
            $x++
        } #end foreach tablelist
        $i++
    } #end foreach file
    $sqlcn.Close()
#    Pop-Location
}