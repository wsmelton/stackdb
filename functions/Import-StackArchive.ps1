function Import-StackArchive {
    <#
        .SYNOPSIS
            Pulls XML dump file and bulk loads into database

        .DESCRIPTION
            Imports the XML dump file and then uses bulk load method to import into specified database

        .PARAMETER Folder
            The path to where the uncompressed XML files are located for the StackExchange site

        .PARAMETER SqlServer
            SQL Server instance were database is located

        .PARAMETER SqlCredential
            Credential object to connect as another user to SQL Server.

        .PARAMETER Database
            Database where you want to import the data

        .PARAMETER Schema
            Defaults to "dbo", specify schema if using specific one

        .PARAMETER TableList
            If you want to granularly load tables for demos or refresh a table.

        .PARAMETER BatchSize
            Set the batch size for the bulk copy process, default to 2000. May want to adjust when loading SO database.

        .EXAMPLE
            Import-StackArchive -Folder 'C:\quant.stackexchange.com' -SqlServer SQL12 -Database StackExchange -Schema quant -TableList Badges

            Import the Badges table from quant archive into the database StackExchange on SQL12

        .EXAMPLE
            Import-StackArchive -Folder 'C:\quant.stackexchange.com' -SqlServer SQL12 -Database StackExchange -Schema quant -TableList 'Badges','Votes'

            Import the Badges and Votes data from quant archive into the database StachExchange on SQL12

        .EXAMPLE
            Import-StackArchive -Folder 'C:\quant.stackexchange.com' -SqlServer SQL12 -Database StackExchange

            Import all data from quant archive into the database StackExchange on SQL12.
    #>
    [CmdletBinding()]
    param (
        [string]$Folder,
        [string]$SqlServer,
        [PSCredential]$SqlCredential,
        [string]$Database,
        [string]$Schema = 'dbo',
        [ValidateSet('Badges', 'Comments', 'PostHistory', 'PostLinks', 'Posts', 'Tags', 'Users', 'Votes')]
        [string[]]$TableList,
        [int]$BatchSize
    )

    if ( !(Test-Path $Folder) ) {
        Stop-PSFFunction -Message "$Folder does not exist!"
        return
    }
    if (Test-PSFParameterBinding 'BatchSize' -Not) {
        $BatchSize = 2000
    }
    if (Test-PSFParameterBinding 'TableList' -Not) {
        $TableList = 'Badges', 'Comments', 'PostHistory', 'PostLinks', 'Posts', 'Tags', 'Users', 'Votes'
    }

    $fileList = 'Badges.xml', 'Comments.xml', 'PostHistory.xml', 'PostLinks.xml', 'Posts.xml', 'Tags.xml', 'Users.xml', 'Votes.xml'

    $files = Get-ChildItem -Path $Folder | Where-Object Name -in $FileList | Select-Object Name, BaseName

    Write-PSFMessage -Level Verbose -Message "Connecting to $SqlServer"
    try {
        $instance = Connect-DbaInstance -SqlInstance $SqlServer -SqlCredential $SqlCredential -ClientName "StackDb PowerShell Module - StackExchange Archive"
    }
    catch {
        Stop-PSFFunction -Message "Failure" -Category ConnectionError -Target $SqlServer -ErrorRecord $_
        return
    }

    try {
        $bulkLoad = New-Object ("System.Data.SqlClient.SqlBulkCopy") $instance.ConnectionContext.ConnectionString
        $bulkLoad.BatchSize = $batchSize
    }
    catch {
        Stop-PSFFunction -Message "Issue creating bulk load object" -ErrorRecord $_
        return
    }

    $i=$x = 1
    foreach ($f in $files) {
        Write-Progress -Id 1 -Activity "Working on files" -Status "Processing $($f.Name)" -PercentComplete $i
        foreach ($t in $TableList) {
            Write-Progress -Id 2 -Activity "Working on Tables" -Status "Processing $t" -PercentComplete $x
            if (Test-Path $f.Name ) {
                if ($t -eq $f.BaseName) {
                    switch ($t) {
                        "Badges" {
                            Write-PSFMessage -Level Verbose -Message "Found Badges file..."
                            [xml]$badges = Get-Content $f.Name
                            $badgesDt = $badges.badges.Row | Select-Object UserId, Name, Date | Out-DbaDataTable
                            $bulkLoad.DestinationTableName = "$schema.$t"
                            Write-PSFMessage -Level Verbose -Message "Bulk loading Badges file..."
                            $bulkLoad.WriteToServer($badgesDt)
                        }
                        "Comments" {
                            Write-PSFMessage -Level Verbose -Message "Found Comments file..."
                            [xml]$comments = Get-Content $f.Name
                            $commentsDt = $comments.comments.row | Select-Object Id, PostId, Score, Text, CreationDate, UserId | Out-DbaDataTable
                            $bulkLoad.DestinationTableName = "$schema.$t"
                            Write-PSFMessage -Level Verbose -Message "Bulk loading Comments file..."
                            $bulkLoad.WriteToServer($commentsDt)
                        }
                        "PostHistory" {
                            Write-PSFMessage -Level Verbose -Message "Found PostHistory file..."
                            [xml]$postHistory = Get-Content $f.Name
                            $postHistoryDt = $postHistory.posthistory.row | Select-Object Id, PostHistoryTypeId, PostId, RevisionGUID, CreationDate,
                            UserId, UserDisplayName, Comment, Text, CloseReasonId | Out-DbaDataTable
                            $bulkLoad.DestinationTableName = "$schema.$t"
                            Write-PSFMessage -Level Verbose -Message "Bulk loading PostHistory file..."
                            $bulkLoad.WriteToServer($postHistoryDt)
                        }
                        "PostLinks" {
                            Write-PSFMessage -Level Verbose -Message "Found PostLinks file..."
                            [xml]$postLink = Get-Content $f.Name
                            $postLinkDt = $postLink.postlinks.row | Select-Object Id, CreationDate, PostId, RelatedPostId, LinkTypeId | Out-DbaDataTable
                            $bulkLoad.DestinationTableName = "$schema.$t"
                            Write-PSFMessage -Level Verbose -Message "Bulk loading PostLinks file..."
                            $bulkLoad.WriteToServer($postLinkDt)
                        }
                        "Posts" {
                            Write-PSFMessage -Level Verbose -Message "Found Posts file..."
                            [xml]$posts = Get-Content $f.Name
                            $postsDt = $posts.posts.row | Select-Object Id, PostTypeId, ParentId, AcceptedAnswerId, CreationDate, Score, ViewCount,
                            Body, OwnerUserId, LastEditorUserId, LastEditorDisplayName, LastEditDate, LastActivityDate, CommunityOwnedDate,
                            ClosedDate, Title, Tags, AnswerCount, CommentCount, FavoriteCount | Out-DbaDataTable
                            $bulkLoad.DestinationTableName = "$schema.$t"
                            Write-PSFMessage -Level Verbose -Message "Bulk loading Posts file..."
                            $bulkLoad.WriteToServer($postsDt)
                        }
                        "Tags" {
                            Write-PSFMessage -Level Verbose -Message "Found Tags file..."
                            [xml]$tags = Get-Content $f.Name
                            $tagsDt = $tags.tags.row | Select-Object Id, TagName, Count, ExcerptPostId, WikiPostId | Out-DbaDataTable
                            $bulkLoad.DestinationTableName = "$schema.$t"
                            Write-PSFMessage -Level Verbose -Message "Bulk loading Tags file..."
                            $bulkLoad.WriteToServer($tagsDt)
                        }
                        "Users" {
                            Write-PSFMessage -Level Verbose -Message "Found Users file..."
                            [xml]$users = Get-Content $f.Name
                            $usersDt = $users.users.row | Select-Object Id, Reputation, CreationDate, DisplayName, EmailHash, LastAccessDate, WebsiteUrl,
                            Location, Age, AboutMe, Views, UpVotes, DownVotes | Out-DbaDataTable
                            $bulkLoad.DestinationTableName = "$schema.$t"
                            Write-PSFMessage -Level Verbose -Message "Bulk loading Users file..."
                            $bulkLoad.WriteToServer($usersDt)
                        }
                        "Votes" {
                            Write-PSFMessage -Level Verbose -Message "Found Votes file..."
                            [xml]$votes = Get-Content $f.Name
                            $votesDt = $votes.votes.row | Select-Object Id, PostId, VoteTypeId, CreationDate, UserId, BountyAmount | Out-DbaDataTable
                            $bulkLoad.DestinationTableName = "$schema.$t"
                            Write-PSFMessage -Level Verbose -Message "Bulk loading Votes file..."
                            $bulkLoad.WriteToServer($votesDt)
                        }
                    } #end switch $t
                } #end if test basename
            } #end if test name
            else {
                Write-PSFMessage -Level Warning -Message "No valid files found in provided directory"
            }
            $x++
        } #end foreach tablelist
        $i++
    } #end foreach file
}