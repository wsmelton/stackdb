function New-SETables
{
	[cmdletbinding()]
	param()
    $sqlCn = New-Object System.Data.SqlClient.SqlConnection("Data Source=$($server);Integrated Security=SSPI;Initial Catalog=$($database)");
}