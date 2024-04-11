## SQL to SQLite3 Powershell


This script was designed to make a simple data exchange between SQL Server and SQLite3 more easily achievable instead of using .NET ORM's and multiple connections through an application, this script can be executed as is and achieve a basic .db file output


## Dependencies

- **Powershell 3.0+** - this script uses features available in Powershell 3.0 and higher. Depending on your version of windows you may be able to run the following command to get the latest version of Powershell ```winget search Microsoft.Powershell``` and then install the appropriate verison ```winget install --id Microsoft.Powershell --source winget```
- **.NET Framework** - This script uses the ```System.Data.SqlCLient.SqlConnection``` class, which is part of the .NET Framework. YOu'll need at least **.NET Framework 4.5** to use ```System.Data.SqlClient```. This c)n be downloaded [here](https://dotnet.microsoft.com/en-us/download/dotnet-framework)
- **SQL Sever** - this script is inteded to interface with a SQL Server instance to fetch data from and create CSV and finally a .db file
- **SQLite CLI Tools** - these can be downloaded from [here](https://www.sqlite.org/download.html)
- **CSV File Storage** - because this script creates CSV files it's important to ensure the path you're providing has read/write permissions for the user that executes this script.
- **Execution Policy** - dependent on y our systems execution policy for Powershell scripts, you might need to adjust it to run this sript. Use ```Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process``` to change the policy if necessary. Please be sure of what you're doing when changing Powershell and script execution policies.
- **Administrator Privileges** - due to the nature of this script you may require administrative privileges on your machine

## Notes

Before running this script please make sure that you have read and/or followed the dependency guideline to be aware of the items necessary for execution and usage.
