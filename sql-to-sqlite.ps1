# set sql connection variables
$dbServer = "your_db_server"
$dbName = "your_db_name"
$tblNames = @("TABLE1", "TABLE2", "TABLE3", "TABLE4") # Add your table names here
$dbUsername = ""
$dbPassword = ""
$csvFileDirectory = "path_to_place_csv_files"
$sqliteFile = "path_to_your_db_file"
$isComplete = $true
$variablesLoaded = $false
$fileOutputPath = ".\variables.ps1"

# the sqlite3 cli can be downloaded here:
# https://www.sqlite.org/download.html -- grab the binary for your OS
# Set variables for SQLite connection
$sqliteExecutable = "path_to_your_sqlite3_executable"

# prompt for database credentials
Write-Host "Please enter your database credentials." -ForegroundColor Yellow
Write-Host "If you have these saved in your variables config you can just press enter when prompted..." -ForegroundColor Yellow

# check for variables.ps1 override / storage
If(Test-Path $fileOutputPath) {
    if((Read-Host -Prompt "It appears you have values that can be loaded. `nWould you like to use the variables stored in variables.ps1? (y/n)").ToLower() -eq "y") {
            . $fileOutputPath
            $variablesLoaded = $true
            Write-Host "Variables loaded from variables.ps1" -ForegroundColor Cyan
    }
}

if($variablesLoaded -eq $false) {
    # collect values and prompt for storage
    $dbServer = Read-Host -Prompt "Enter your database server"
    $dbName = Read-Host -Prompt "Enter your database name"
    $tblNames = Read-Host -Prompt "Enter the table names you like to export (comma separated)"
    $dbUsername = Read-Host -Prompt "Enter your database username"
    $dbPassword = Read-Host -Prompt "Enter your database password"
    $csvFileDirectory = Read-Host -Prompt "Enter the directory to save CSV files"
    $sqliteFile = Read-Host -Prompt "Enter the path where you would like to save your SQLite database (.db) file"
    sqliteExecutable = Read-Host -Prompt "Enter the path to your SQLite3 executable"

    $tblArray = $tblNames -split ',' | ForEach-Object { "`"$_`"" }

    Write-Host "`n"

    if((Read-Host -Prompt "Would you like to save these variables for future use? (y/n)" ).ToLower() -eq "y"){

        if(Test-Path $fileOutputPath) {
            Clear-Content $fileOutputPath
        } else {
            New-Item $fileOutputPath -ItemType File
        }

        Write-Host "Writing variables to variables.ps1" -ForegroundColor Yellow

        "`$dbServer = `"$dbServer`"" | Out-File $fileOutputPath -Append 
        "`$dbName = `"$dbName`"" | Out-File $fileOutputPath -Append
        "`$tblNames = @($($tblArray -join ', '))" | Out-File $fileOutputPath -Append
        "`$dbUsername = `"$dbUsername`"" | Out-File $fileOutputPath -Append
        "`$dbPassword = `"$dbPassword`"" | Out-File $fileOutputPath -Append
        "`$csvFileDirectory = `"$csvFileDirectory`"" | Out-File $fileOutputPath -Append
        "`$sqliteFile = `"$sqliteFile`"" | Out-File $fileOutputPath -Append
        "`$sqliteExecutable = `"$sqliteExecutable`"" | Out-File $fileOutputPath -Append

        Write-Host "successfully saved variables to variables.ps1" -ForegroundColor Green
    }
}

Write-Host "Using user $dbUsername to connect to $serverInstance..." -ForegroundColor Yellow

# mssql connection object setup
# this connection string can be modified to use integrated security mode, sspi, etc.
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection
$sqlConnectionString = "Server=$dbServer;Database=$dbName;User ID=$dbUsername;Password=$dbPassword"

# try to open sql connection
try {
    $sqlConnection.ConnectionString = $sqlConnectionString
    $sqlConnection.Open()
} catch {
    Write-Host "Error connecting to SQL Server." -ForegroundColor Red
    Write-Host "An error occured: $_" -ForegroundColor Red
    exit
}

# iterate over the tbales
foreach ($tableName in $tblNames) {
    try {
        Write-Host "Attempting to fetch and export data for table $tableName..." -ForeGroundColor Yellow

        # declare csv output from table
        $csvFile = "$csvFileDirectory\$tableName.csv"

        # drop staging table(s) for fresh data
        $sqlDropTableCommandText = "DROP TABLE IF EXISTS sqlite_$tableName"
        
        # connect to SQL Server and export data to CSV
        $sqlQuery = "SELECT * FROM sqlite_$tableName"

        # drop this table if exists, then
        $sqlDropTableCommand = New-Object System.Data.SqlClient.SqlCommand($sqlDropTableCommandText, $sqlConnection)
        $sqlDropTableCommand.ExecuteNonQuery()

        # create the table and remove the un-used columns
        $sqlCreateTableCommandText = "SELECT * INTO sqlite_$tableName FROM $tableName"
        $sqlCreateTableCommand = New-Object System.Data.SqlClient.SqlCommand($sqlCreateTableCommandText, $sqlConnection)
        $sqlCreateTableCommand.ExecuteNonQuery()

        # fetch table data
        Write-Host "Exporting $tableName to $csvFile..." -ForegroundColor Yellow

        $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($sqlQuery, $sqlConnection)
        $sqlReader = $sqlCommand.ExecuteReader()
        $dataTable = New-Object System.Data.DataTable
        $dataTable.Load($sqlReader)
        $dataTable | Export-Csv -Path $csvFile -NoTypeInformation

        # connect to SQLite and import CSV data
        $sqliteCommand = "$sqliteExecutable "
        $sqliteCommand += "-cmd "".mode csv"" $sqliteFile "
        $sqliteCommand += """.import '$csvFile' $tableName"""

        Write-Host "Successfully wrote data to database" -ForegroundColor Green
        Invoke-Expression $sqliteCommand
    } catch {
        Write-Host "Error working with table $tableName." -ForegroundColor Red
        Write-Host "An error occured: $_" -ForegroundColor Red
        $isComplete = $false
    }
}

# check if the sql connection is open and if it is, close it
if($sqlConnection.State -eq [System.Data.ConnectionString]::Open) {
    $sqlConnection.Close()
}

# add isComplete flag check for final output
if ($isComplete) {
    Write-Host "All tables exported successfully!" -ForegroundColor Cyan
} else {
    Write-Host "There was an error exporting one or more tables. The process did not complete successfully." -ForegroundColor Red
}