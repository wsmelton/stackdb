# Summary

PowerShell module to build an SQL Server database(s) from the [StackExchange Archives](https://archive.org/details/stackexchange). You can use this to create the database, tables and then import the data.

<table>
  <tbody>
    <tr>
      <td><img align="left" src="https://wshawnmelton.visualstudio.com/_apis/public/build/definitions/640c5abb-34bd-4423-9e10-8f7e92e7f918/2/badge"></td>
<td>Dev Build Status</td>
</tr>
<tr><td><img align="left" src="https://wshawnmelton.visualstudio.com/_apis/public/build/definitions/640c5abb-34bd-4423-9e10-8f7e92e7f918/1/badge"></td><td>CI Status</td>
</tr>
</tbody>
</table>

# Example

The example below shows the general process to utilize in order to create a database from StackExchange data dumps:

```powershell
Install-Module stackdb

C:\> Get-StackArchive -SiteName woodworking -ListSite | Select-Object TinyName, Name, Total* | Format-Table

TinyName      Name             TotalQuestions TotalAnswers TotalUsers TotalComments TotalTags
--------      ----             -------------- ------------ ---------- ------------- ---------
woodworking   Woodworking      2142           4531         4852       12451         205
woodworkingme Woodworking Meta 124            228          335        596           72
```

I want to create a database for the woodworking data dump.

```powershell
C:\> Get-StackArchive -SiteName woodworking -DownloadPath c:\temp
[Get-StackArchive] Downloading https://archive.org/download/stackexchange/woodworking.stackexchange.com.7z to c:\temp\woodworking.stackexchange.com.7z][Get-StackArchive] Download completed!
C:\> Get-ChildItem C:\temp\woodworking.stackexchange.com.7z

    Directory: C:\temp


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----       2018-06-08   8:47 PM        7038655 woodworking.stackexchange.com.7z
```

I need to expand that 7z file to access the XML files of the data dump. This will assume that you have 7z installed using the Windows installer. If you have happen to have just the executable (exe) you can set this at the module level using `Set-StackdbConfig -Name zpp.7zippath -Value 'C:\whatever\7z.exe'`

```powershell
C:\> Expand-StackArchive -FileName C:\temp\woodworking.stackexchange.com.7z -ExportPath c:\temp

7-Zip 18.05 (x64) : Copyright (c) 1999-2018 Igor Pavlov : 2018-04-30

Scanning the drive for archives:
1 file, 7038655 bytes (6874 KiB)

Extracting archive: C:\temp\woodworking.stackexchange.com.7z
--
Path = C:\temp\woodworking.stackexchange.com.7z
Type = 7z
Physical Size = 7038655
Headers Size = 306
Method = BZip2
Solid = +
Blocks = 1

Everything is Ok

Files: 8
Size:       37051719
Compressed: 7038655
```

The next thing I need is a database to import the data. I use containers for my most of my testing and all of my database files reside under `C:\sqlfiles`:

```powershell
C:\> New-StackDatabase -SqlServer 'localhost,1416' -DatabaseName 'woodworkingse' -DataPath c:\sqlfiles -LogPath c:\sqlfiles
[20:59:35][New-StackDatabase] woodworkingse created on [localhost,1416]
 C:\> Get-DbaDatabase -SqlInstance 'localhost,1416' -Database 'woodworkingse' | ft

ComputerName InstanceName SqlInstance  Name          Status IsAccessible RecoveryModel LogReuseWaitStatus SizeMB Compatibility Collation
------------ ------------ -----------  ----          ------ ------------ ------------- ------------------ ------ ------------- ---------
67D218C1FB41 MSSQLSERVER  67D218C1FB41 woodworkingse Normal         True          Full            Nothing    175    Version130 SQL_Latin1_Gen...
```

Now we just need to import all the data into the pre-built tables.

```powershell
C:\> Import-StackArchive -Folder C:\temp\woodworking.stackexchange.com\ -SqlServer 'localhost,1416'-Database woodworkingse -Schema 'dbo'
C:\> Get-DbaTable -SqlInstance 'localhost,1416' -Database woodworkingse | select database, schema, name, rowcount
Database      Schema Name                  RowCount
--------      ------ ----                  --------
woodworkingse dbo    Badges                    9377
woodworkingse dbo    CloseReasonIdDesc            5
woodworkingse dbo    Comments                 12451
woodworkingse dbo    PostHistory              17261
woodworkingse dbo    PostHistoryTypeIdDesc       22
woodworkingse dbo    PostLinks                  889
woodworkingse dbo    PostLinkTypeIdDesc           2
woodworkingse dbo    Posts                     6903
woodworkingse dbo    PostsTypeIdDesc              2
woodworkingse dbo    Tags                       205
woodworkingse dbo    Users                     4852
woodworkingse dbo    Votes                    33576
woodworkingse dbo    VoteTypeIdDesc              13
```

## ToDo

- Build out `Invoke-StackDatabase`, wrapper function that calls all supported commands in proper sequence. Can use splatting to handle all the parameters that will be required.
    1. Get-StackArchive
    2. Expand-StackArchive
    3. New-StackDatabase (deal with if database does not exist, or if it does and tables don't)
    4. Import-StackArchive (all of it)
