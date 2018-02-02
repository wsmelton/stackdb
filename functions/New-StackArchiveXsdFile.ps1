function New-StackArchiveXsdFile {
<#
	.SYNOPSIS
		Pulls XML file and generates a XSD file.
	.DESCRIPTION
		Creates a schema file (XSD).
	.PARAMETER xmlFile
		The path to the xml file
    .PARAMETER xsdFile
        The path and name of the XSD file desired.
    .PARAMETER force
        Overwrite the current XSD file.
	.EXAMPLE
	Generate XSD file for the Badges.XML
    New-StackArchiveXsdFile -xmlFile 'C:\temp\quant.stackexchange.com\Badges.xml' -xsdFile 'C:\temp\quant.stackexchange.com\Badges.xsd'

    .NOTES
    Genearl sources used for generate this code and why it would be useful.
    https://www.simple-talk.com/sql/sql-tools/sqlxml-bulk-loader-basics/
    http://learningpcs.blogspot.com/2012/08/powershell-v3-inferring-schema-xsd-from.html
    https://www.mssqltips.com/sqlservertip/3141/importing-xml-documents-using-sql-server-integration-services/
#>

    [cmdletbinding()]
    param (
        [string]$xmlFile,
        [string]$xsdFile,
        [switch]$force
    )

    if ( (Test-Path $xsdFile) -and (!$force) ) {
        throw "The XSD file [$xsdFile] already exist, use -Force to overwrite."
    }
    elseif (Test-Path $xsdFile) {
        Remove-Item -Path $xsdFile -Force
    }

    $xmlRead

}
