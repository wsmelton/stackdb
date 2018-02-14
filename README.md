# Summary

PowerShell module to build an SQL Server database(s) from the [StackExchange Archives](https://archive.org/details/stackexchange). You can use this to create the database, tables and then import the data.

Write-up and example of module can be found [here](http://blog.wsmelton.info/stackexchange/).

## ToDo

- Rename module to `StackDb` [Done 02/02/2018].
- Rename functions to prefix just `Stack` instead of `SE` [Done February 2018]
- Add [PSFramework](https://github.com/PowershellFrameworkCollective/psframework) [Done 02/13/2018]
- Implement features of PSFramework [Done 02/13/2018]
- Tests, tests, tests
- Build out CI with (VSTS, GitHub and Appveyor once test are written](https://docs.microsoft.com/en-us/vsts/build-release/actions/ci-build-github)
- Part of CI with VSTS implement push to PS Gallery.