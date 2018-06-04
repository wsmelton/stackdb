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

            Import the Badges and Votes data from quant archive into the database StackExchange on SQL12

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
    begin {
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

        $files = Get-ChildItem -Path $Folder | Where-Object Name -in $FileList

        if ($files.Count -le 0) {
            Write-PSFMessage -Level Warning -Message "No files found in $Folder"
            return
        }
        Write-PSFMessage -Level Verbose -Message "Connecting to $SqlServer"
        try {
            $instance = Connect-DbaInstance -SqlInstance $SqlServer -SqlCredential $SqlCredential -ClientName "StackDb PowerShell Module - StackExchange Archive"
        }
        catch {
            Stop-PSFFunction -Message "Failure" -Category ConnectionError -Target $SqlServer -ErrorRecord $_
            return
        }

        if ( -not (Get-DbaDatabase -SqlInstance $instance -Database $Database) ) {
            Stop-PSFFunction -Message "$Database not found on $instance" -Target $instance
            return
        }
    }
    process {
        if (Test-PSFFunctionInterrupt) {return}
        $i = $x = 1
        foreach ($f in $files) {
            Write-Progress -Id 1 -Activity "Working on files" -Status "Processing $($f.Name)" -PercentComplete $i
            foreach ($t in $TableList) {
                Write-Progress -Id 2 -Activity "Working on Tables" -Status "Processing $t" -PercentComplete $x
                if (Test-Path $f.FullName ) {
                    if ($t -eq $f.BaseName) {
                        switch ($t) {
                            "Badges" {
                                Write-PSFMessage -Level Verbose -Message "Found $f file..."
                                [xml]$badges = Get-Content $f.FullName
                                $dataTable = $badges.badges.Row | Select-Object UserId, Name, Date | ConvertTo-DbaDataTable
                                Write-PSFMessage -Level Verbose -Message "Bulk loading Badges file..."
                                Write-DbaDataTable -SqlInstance $instance -Database $Database -Schema $Schema -Table $t -InputObject $dataTable -BatchSize $BatchSize
                            }
                            "Comments" {
                                Write-PSFMessage -Level Verbose -Message "Found $f file..."
                                [xml]$comments = Get-Content $f.FullName
                                $dataTable = $comments.comments.row | Select-Object Id, PostId, Score, Text, CreationDate, UserId | ConvertTo-DbaDataTable
                                Write-PSFMessage -Level Verbose -Message "Bulk loading $f file..."
                                Write-DbaDataTable -SqlInstance $instance -Database $Database -Schema $Schema -Table $t -InputObject $dataTable -BatchSize $BatchSize
                            }
                            "PostHistory" {
                                Write-PSFMessage -Level Verbose -Message "Found $f file..."
                                [xml]$postHistory = Get-Content $f.FullName
                                $dataTable = $postHistory.posthistory.row | Select-Object Id, PostHistoryTypeId, PostId, RevisionGUID, CreationDate,
                                UserId, UserDisplayName, Comment, Text, CloseReasonId | ConvertTo-DbaDataTable
                                Write-PSFMessage -Level Verbose -Message "Bulk loading $f file..."
                                Write-DbaDataTable -SqlInstance $instance -Database $Database -Schema $Schema -Table $t -InputObject $dataTable -BatchSize $BatchSize
                            }
                            "PostLinks" {
                                Write-PSFMessage -Level Verbose -Message "Found $f file..."
                                [xml]$postLink = Get-Content $f.FullName
                                $dataTable = $postLink.postlinks.row | Select-Object Id, CreationDate, PostId, RelatedPostId, LinkTypeId | ConvertTo-DbaDataTable
                                Write-PSFMessage -Level Verbose -Message "Bulk loading $f file..."
                                Write-DbaDataTable -SqlInstance $instance -Database $Database -Schema $Schema -Table $t -InputObject $dataTable -BatchSize $BatchSize
                            }
                            "Posts" {
                                Write-PSFMessage -Level Verbose -Message "Found $f file..."
                                [xml]$posts = Get-Content $f.FullName
                                $dataTable = $posts.posts.row | Select-Object Id, PostTypeId, ParentId, AcceptedAnswerId, CreationDate, Score, ViewCount, Body, OwnerUserId, LastEditorUserId, LastEditorDisplayName, LastEditDate, LastActivityDate, CommunityOwnedDate, ClosedDate, Title, Tags, AnswerCount, CommentCount, FavoriteCount | ConvertTo-DbaDataTable
                                Write-PSFMessage -Level Verbose -Message "Bulk loading $f file..."
                                Write-DbaDataTable -SqlInstance $instance -Database $Database -Schema $Schema -Table $t -InputObject $dataTable -BatchSize $BatchSize
                            }
                            "Tags" {
                                Write-PSFMessage -Level Verbose -Message "Found $f file..."
                                [xml]$tags = Get-Content $f.FullName
                                $dataTable = $tags.tags.row | Select-Object Id, TagName, Count, ExcerptPostId, WikiPostId | ConvertTo-DbaDataTable
                                Write-PSFMessage -Level Verbose -Message "Bulk loading $f file..."
                                Write-DbaDataTable -SqlInstance $instance -Database $Database -Schema $Schema -Table $t -InputObject $dataTable -BatchSize $BatchSize
                            }
                            "Users" {
                                Write-PSFMessage -Level Verbose -Message "Found $f file..."
                                [xml]$users = Get-Content $f.FullName
                                $dataTable = $users.users.row | Select-Object Id, Reputation, CreationDate, DisplayName, EmailHash, LastAccessDate, WebsiteUrl,
                                Location, Age, AboutMe, Views, UpVotes, DownVotes | ConvertTo-DbaDataTable
                                Write-PSFMessage -Level Verbose -Message "Bulk loading $f file..."
                                Write-DbaDataTable -SqlInstance $instance -Database $Database -Schema $Schema -Table $t -InputObject $dataTable -BatchSize $BatchSize
                            }
                            "Votes" {
                                Write-PSFMessage -Level Verbose -Message "Found $f file..."
                                [xml]$votes = Get-Content $f.FullName
                                $dataTable = $votes.votes.row | Select-Object Id, PostId, VoteTypeId, CreationDate, UserId, BountyAmount | ConvertTo-DbaDataTable
                                Write-PSFMessage -Level Verbose -Message "Bulk loading $f file..."
                                Write-DbaDataTable -SqlInstance $instance -Database $Database -Schema $Schema -Table $t -InputObject $dataTable -BatchSize $BatchSize
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
}