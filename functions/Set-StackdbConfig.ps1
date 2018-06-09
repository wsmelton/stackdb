function Set-StackdbConfig {
    <#
        .SYNOPSIS
            Sets configuration entries.

        .DESCRIPTION
            This function creates or changes configuration values for StackDb module.

        .PARAMETER Name
            Name of the configuration entry.

        .PARAMETER Value
            The value to assign to the named configuration element.

        .PARAMETER EnableException
            By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
            This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
            Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

        .EXAMPLE
            Set-StackdbConfig -Name app.7zippath -Value c:\7z\7z.exe

            Updates the current configuration to point at the 7z executable
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding(DefaultParameterSetName = "FullName")]
    param (
        [string]$Name,
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        $Value,
        [switch]$EnableException
    )

    process {
        if (-not (Get-StackdbConfig -Name $Name)) {
            Stop-PSFFunction -Message "Setting named $Name does not exist. If you'd like us to support an additional setting, please file a GitHub issue."
            return
        }

        if ($append) {
            $Value = (Get-StackdbConfigValue -Name $Name), $Value
        }

        $Name = $Name.ToLower()

        Set-PSFConfig -Module stackdb -Name $name -Value $Value
        try {
            Register-PSFConfig -FullName stackdb.$name -EnableException -WarningAction SilentlyContinue
        }
        catch {
            Set-PSFConfig -Module stackdb -Name $name -Value $Value
            Register-PSFConfig -FullName stackdb.$name
        }

        Get-DbcConfig -Name $name
    }
}