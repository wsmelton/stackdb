function New-SETables
{
	[CmdletBinding(DefaultParameterSetName = "Default", SupportsShouldProcess = $true)]
	param(
		[System.Data.SqlClient.SqlConnection]$sqlCn,
		[string]$databaseName,
		[string]$dataPath,
		[string]$logPath = $dataPath
	)
	BEGIN
	{
		$dataPath = $dataPath.TrimEnd("\")
		$logPath = $logPath.TrimEnd("\")
	}
	PROCESS
	{
		$sql = "CREATE DATABASE $databaseName 
		ON PRIMARY (NAME = $databaseName_data, FILENAME = '$dataPath\$databaseName_data.mdf', SIZE = 150MB, FILEGROWTH = 25MB)
		LOG ON (NAME = $databaseName_log, FILENAME = '$logPath\$databaseName_log.ldf', SIZE = 25MB, FILEGROWTH = 150MB)"
		Write-Debug $sql

		if ($PSCmdlet.ShouldProcess($databaseName,"Create database: $databaseName"))
		{
			Write-Output "$databaseName Created"
		}

		# database created now adjust settings
		$sqlCn.ChangeDatabase($databaseName)
		$sql = "ALTER DATABASE $databaseName SET RECOVERY SIMPLE;"
		if ($PSCmdlet.ShouldProcess($databaseName,"Adjusted recovery model"))
		{
			Write-Output "$databaseName set to SIMPLE recovery";
		}
	}
}