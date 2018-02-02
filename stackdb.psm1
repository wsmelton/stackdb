if ( (Get-Module dbatools -ListAvailable).Count -eq 0) {
    throw "The dbatools module was not found, please install before trying to use PSStackExchangeDb module."
}
# All exported functions
foreach ($function in (Get-ChildItem "$PSScriptRoot\functions\*.ps1")) {. $function }

# Internal functions
function Out-DataTable {
    <#
    .SYNOPSIS
    Creates a DataTable for an object (http://poshcode.org/2119)
    .DESCRIPTION
    Creates a DataTable based on an objects properties.
    .INPUTS
    Object
        Any object can be piped to Out-DataTable
    .OUTPUTS
    System.Data.DataTable
    .EXAMPLE
    $dt = Get-Alias | Out-DataTable
    This example creates a DataTable from the properties of Get-Alias and assigns output to $dt variable
    .NOTES
    Adapted from script by Marc van Orsouw see link
    Version History
    v1.0   - Chad Miller - Initial Release
    v1.1   - Chad Miller - Fixed Issue with Properties
    .LINK
    http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx
    #>
    [CmdletBinding()]
    param([Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)] [PSObject[]]$InputObject)

    BEGIN {
        $dt = new-object Data.datatable
        $First = $true
    }
    PROCESS {
        foreach ($object in $InputObject) {
            $DR = $DT.NewRow()
            foreach($property in $object.PsObject.get_properties()) {
                if ($first) {
                    $Col =  new-object Data.DataColumn
                    $Col.ColumnName = $property.Name.ToString()
                    $DT.Columns.Add($Col)
                }
                if ($property.IsArray) {
                    $DR.Item($property.Name) =$property.value | ConvertTo-XML -AS String -NoTypeInformation -Depth 1
                }
                else {
                    $DR.Item($property.Name) = $property.value
                }
            }
            $DT.Rows.Add($DR)
            $First = $false
        }
    }

    END {
        Write-Output @(,($dt))
    }
}
function New-SqlCn {
    [cmdletbinding()]
    param(
        [string]$sqlserver,
        [string]$database = 'master',
        [System.Management.Automation.PSCredential]$credential
    )

    $sqlcn = New-Object System.Data.SqlClient.SqlConnection
    try {
        if ($credential -ne $null) {
            $username = $credential.username
            $password = $credential.password

            if ($username -like "*\*") {
                throw "Username $($username) looks like a Windows Account. This is not supported!!! If you are trying to run this as a different Windows Account try running the PowerShell process as that account to use this module and Windows Authentication."
            }
            $cred = New-Object System.Data.SqlClient.SqlCredential($username,$password)
            $cnString = "Data Source=$($sqlserver);Database=$($database);"
        }
        else {
            $cnString = "Data Source=$($sqlserver);Integrated Security=SSPI;Initial Catalog=$($database)"
        }

        $sqlcn.ConnectionString = $cnString
        $sqlcn.Credential = $cred

        $sqlcn.Open()
    }
    catch {
        $msg = $_.Exception.InnerException.InnerException
        $msg = $msg.ToString()
        throw "Can't connect to $sqlserver`: $msg"
    }

    if ($sqlcn.State -eq "Open") {
        return $sqlcn
    }
    else {
        throw "Connection was not opened properly."
    }
}