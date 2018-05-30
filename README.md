# Summary

PowerShell module to build an SQL Server database(s) from the [StackExchange Archives](https://archive.org/details/stackexchange). You can use this to create the database, tables and then import the data.

<img align="left" src="https://wshawnmelton.visualstudio.com/_apis/public/build/definitions/640c5abb-34bd-4423-9e10-8f7e92e7f918/2/badge"> Dev Build Status
<img align="left" src="https://wshawnmelton.visualstudio.com/_apis/public/build/definitions/640c5abb-34bd-4423-9e10-8f7e92e7f918/1/badge"> CI Status
<img align="left" src="https://wshawnmelton.vsrm.visualstudio.com/_apis/public/Release/badge/640c5abb-34bd-4423-9e10-8f7e92e7f918/1/1)"> Release Status

## ToDo

- Tests, tests, tests
- Build out CI with (VSTS](https://docs.microsoft.com/en-us/vsts/build-release/actions/ci-build-github)
- Part of CI with VSTS implement push to PS Gallery.
- Build out `Invoke-StackDatabase`, wrapper function that calls all supported commands in proper sequence. Can use splatting to handle all the parameters that will be required.
    1. Get-StackArchive
    2. Expand-StackArchive
    3. New-StackDatabase (deal with if database does not exist, or if it does and tables don't)
    4. Import-StackArchive (all of it)
