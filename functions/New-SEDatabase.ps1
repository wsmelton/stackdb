function New-SEDatabase {
	[CmdletBinding(DefaultParameterSetName = "Default", SupportsShouldProcess = $true)]
	param(
		[string]$sqlServer,
		[string]$databaseName,
		[string]$dataPath,
		[string]$logPath,
		[switch]$justTables
	)
	BEGIN {
		$sqlcn = New-Sqlcn -sqlserver $sqlServer
		$cmd = $sqlcn.CreateCommand()

		$sqlDatabase = "
			CREATE DATABASE $databaseName
				ON PRIMARY (NAME = $($databaseName)_data, FILENAME = '$dataPath\$($databaseName)_data.mdf', SIZE=150MB,FILEGROWTH=25MB)
				LOG ON (NAME = $($databaseName)_log, FILENAME='$logPath\$($databaseName)_log.ldf', SIZE=25MB,FILEGROWTH=150MB)"
		$sqlDbRecoveryModel = "ALTER DATABASE $databaseName SET RECOVERY SIMPLE;"
		$sqlTables = "
			IF (OBJECT_ID('dbo.PostsTypeIdDesc') IS NOT NULL)
				DROP TABLE dbo.PostsTypeIdDesc;
			CREATE TABLE [dbo].[PostsTypeIdDesc] (
				[PostTypeId] int,
				[Description] varchar(10)
			);
			INSERT INTO [dbo].[PostsTypeIdDesc] (PostTypeId,Description)
			VALUES (1,'Question'), (2,'Answer');

			IF (OBJECT_ID('dbo.CloseReasonIdDesc') IS NOT NULL)
				DROP TABLE dbo.CloseReasonIdDesc;
			CREATE TABLE [dbo].[CloseReasonIdDesc] (
				[CloseReasonId] int,
				[Description] varchar(250)
			);

			INSERT INTO [dbo].[CloseReasonIdDesc](CloseReasonId,Description)
			VALUES (1,'Exact Duplicate - This question covers exactly the same ground as earlier questions on this topic; its answers may be merged with another identical question.'),
				(2,'off-topic'),
				(3,'subjective'),
				(4,'not a real question'),
				(7,'too localized');

			IF (OBJECT_ID('dbo.PostHistoryTypeIdDesc') IS NOT NULL)
				DROP TABLE dbo.PostHistoryTypeIdDesc;
			CREATE TABLE [dbo].[PostHistoryTypeIdDesc] (
				[PostHistoryTypeId] int,
				[Description] varchar(150)
			);
			INSERT INTO [dbo].[PostHistoryTypeIdDesc] (PostHistoryTypeId,Description)
			VALUES (1,'Initial Title - The first title a question is asked with.'),
				(2,'Initial Body - The first raw body text a post is submitted with.'),
				(3,'Initial Tags - The first tags a question is asked with.'),
				(4,'Edit Title - A questions title has been changed.'),
				(5,'Edit Body - A posts body has been changed, the raw text is stored here as markdown.'),
				(6,'Edit Tags - A questions tags have been changed.'),
				(7,'Rollback Title - A questions title has reverted to a previous version.'),
				(8,'Rollback Body - A posts body has reverted to a previous version - the raw text is stored here.'),
				(9,'Rollback Tags - A questions tags have reverted to a previous version.'),
				(10,'Post Closed - A post was voted to be closed.'),
				(11,'Post Reopened - A post was voted to be reopened.'),
				(12,'Post Deleted - A post was voted to be removed.'),
				(13,'Post Undeleted - A post was voted to be restored.'),
				(14,'Post Locked - A post was locked by a moderator.'),
				(15,'Post Unlocked - A post was unlocked by a moderator.'),
				(16,'Community Owned - A post has become community owned.'),
				(17,'Post Migrated - A post was migrated.'),
				(18,'Question Merged - A question has had another, deleted question merged into itself.'),
				(19,'Question Protected - A question was protected by a moderator'),
				(20,'Question Unprotected - A question was unprotected by a moderator'),
				(21,'Post Disassociated - An admin removes the OwnerUserId from a post.'),
				(22,'Question Unmerged - A previously merged question has had its answers and votes restored.');

			IF OBJECT_ID('dbo.VoteTypeIdDesc') IS NOT NULL
				DROP TABLE dbo.VoteTypeIdDesc;
			CREATE TABLE [dbo].[VoteTypeIdDesc] (
				[VoteTypeId] int,
				[Description] varchar(65)
			);
			INSERT INTO [dbo].[VoteTypeIdDesc] (VoteTypeId, Description)
			VALUES (1,'AcceptedByOriginator'),
				(2,'UpMod'),
				(3,'DownMod'),
				(4,'Offensive'),
				(5,'Favorite - if VoteTypeId = 5 UserId will be populated'),
				(6,'Close'),
				(7,'Reopen'),
				(8,'BountyStart'),
				(9,'BountyClose'),
				(10,'Deletion'),
				(11,'Undeletion'),
				(12,'Spam'),
				(13,'InformModerator');

			IF OBJECT_ID('dbo.PostLinkTypeIdDesc') IS NOT NULL
				DROP TABLE dbo.PostLinkTypeIdDesc;
			CREATE TABLE [dbo].[PostLinkTypeIdDesc] (
				[PostLinkTypeId] int,
				[Description] varchar(10)
			);
			INSERT INTO [dbo].[PostLinkTypeIdDesc] (PostLinkTypeId, Description)
			VALUES (1,'Linked'), (3,'Duplicate');

			IF OBJECT_ID('dbo.Badges') IS NOT NULL
				DROP TABLE dbo.Badges;
			CREATE TABLE [dbo].[Badges] (
				[UserId] int,
				[Name] varchar(500) NULL,
				[Date] datetime NULL
			);

			IF OBJECT_ID('dbo.Comments') IS NOT NULL
				DROP TABLE dbo.Comments;
			CREATE TABLE [dbo].[Comments] (
				[Id] 		int,
				[PostId] 	int NULL,
				[Score]		int NULL,
				[Text]		varchar(600) NULL,
				[CreationDate] datetime NULL,
				[UserId] int NULL
			);

			IF OBJECT_ID('dbo.Posts') IS NOT NULL
				DROP TABLE dbo.Posts;
			CREATE TABLE [dbo].[Posts] (
				[Id] int,
				[PostTypeId] int NULL,
				[ParentId] int NULL,
				[AcceptedAnswerId] int NULL,
				[CreationDate] datetime NULL,
				[Score] int NULL,
				[ViewCount] int NULL,
				[Body] nvarchar(max) NULL,
				[OwnerUserId] int NULL,
				[LastEditorUserId] int NULL,
				[LastEditorDisplayName] varchar(250) NULL,
				[LastEditDate] datetime NULL,
				[LastActivityDate] datetime NULL,
				[CommunityOwnedDate] datetime NULL,
				[ClosedDate] datetime NULL,
				[Title] varchar(150) NULL,
				[Tags] varchar(150) NULL,
				[AnswerCount] int NULL,
				[CommentCount] int NULL,
				[FavoriteCount] int NULL
			);

			IF OBJECT_ID('dbo.PostHistory') IS NOT NULL
				DROP TABLE dbo.PostHistory;
			CREATE TABLE [dbo].[PostHistory] (
				[Id]		int,
				[PostHistoryTypeId]	int NULL,
				[PostId] int NULL,
				[RevisionGUID] nvarchar(50) NULL,
				[CreationDate] datetime NULL,
				[UserId] int NULL,
				[UserDisplayName] varchar(150) NULL,
				[Comment] nvarchar(max) NULL,
				[Text] nvarchar(max) NULL,
				[CloseReasonId] int NULL
			);

			IF OBJECT_ID('dbo.PostLinks') IS NOT NULL
				DROP TABLE dbo.PostLinks;
			CREATE TABLE [dbo].[PostLinks] (
				[Id] int,
				[CreationDate] datetime NULL,
				[PostId] int NULL,
				[RelatedPostId] int NULL,
				[PostLinkTypeId] int NULL
			);

			IF OBJECT_ID('dbo.Users') IS NOT NULL
				DROP TABLE dbo.Users;
			CREATE TABLE [dbo].[Users] (
				[Id] int,
				[Reputation] int NULL,
				[CreationDate] datetime NULL,
				[DisplayName] varchar(250) NULL,
				[EmailHash] varchar(125) NULL,
				[LastAccessDate] datetime NULL,
				[WebsiteUrl] varchar(250) NULL,
				[Location] varchar(250) NULL,
				[Age] int NULL,
				[AboutMe] varchar(max) NULL,
				[Views] int NULL,
				[UpVotes] int NULL,
				[DownVotes] int NULL
			);

			IF OBJECT_ID('dbo.Votes') IS NOT NULL
				DROP TABLE dbo.Votes;
			CREATE TABLE [dbo].[Votes] (
				[Id] int,
				[PostId] int NULL,
				[VoteTypeId] int NULL,
				[CreationDate] datetime,
				[UserId] int NULL,
				[BountyAmount] int NULL
			);

			IF OBJECT_ID('dbo.Tags') IS NOT NULL
				DROP TABLE dbo.Tags;
			CREATE TABLE [dbo].[Tags] (
				[Id] int,
				[TagName] varchar(250),	
				[Count] int NULL,
				[ExcerptPostId] int NULL,
				[WikiPostId] int NULL
			);"
	}
	PROCESS {
		Write-Verbose "Data Path: $dataPath"
		Write-Verbose "Log Path: $logPath"

		if (!$justTables) {
			$sql = "
				SELECT DefaultDataPath = SERVERPROPERTY('InstanceDefaultDataPath'),
					DefaultLogPath = SERVERPROPERTY('InstanceDefaultLogPath')"
			$cmd.CommandText = $sql
			$adp = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
			$data = New-Object System.Data.DataSet
			$null = $adp.Fill($data)
			$rows = $data.Tables[0].Rows
			$defaultDataPath = $rows.DefaultDataPath
			$defaultLogPath = $rows.DefaultLogPath

			if ($dataPath.Length -eq 0) {
				$dataPath = $defaultDataPath
			}
			if ($logPath.Length -eq 0) {
				$logPath = $defaultLogPath
			}

			$dataPath = $dataPath.TrimEnd("\")
			$logPath = $logPath.TrimEnd("\")

			if ($PSCmdlet.ShouldProcess($databaseName,"Create database: $databaseName")) {
				if (!(Test-Path $dataPath) -and !(Test-Path $logPath)) {
					throw "Paths provided for data or log are not found!"
				}
				Write-Debug $sqlDatabase
				$cmd.CommandText = $sqlDatabase
				try {
					$null = $cmd.ExecuteNonQuery()
				}
				catch {
					throw "Error`: $_"
				}
				Write-Output "[Database] $databaseName Created"
			}
			if ($PSCmdlet.ShouldProcess($databaseName,"Adjusted recovery model")) {
				try {
					$cmd.ComandText = $sqlDbRecoveryModel
					$null = $cmd.ExecuteNonQuery()
				}
				catch {
					throw "Error`: $_"
				}
				Write-Output "[Database] $databaseName set to SIMPLE recovery";
			}
		}

		if ($PSCmdlet.ShouldProcess($databaseName,"Build SE tables")) {
			try {
				$sqlcn.ChangeDatabase($databaseName)
				$cmd.CommandText = $sqlTables
				$null = $cmd.ExecuteNonQuery()
			}
			catch {
				throw "Error`: $_"
			}
		}
	}
	END {
		$sqlcn.Close()
	}
}