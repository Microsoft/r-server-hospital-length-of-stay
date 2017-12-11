<#
.SYNOPSIS
Powershell script for setting up the solution template. 

.DESCRIPTION
This script checks out the solution from github and deploys it to SQL Server on the local Data Science VM (DSVM).

.WARNING: This script is only meant to be run from the solution template deployment process.

.PARAMETER serverName
Name of the server with SQL Server with R Services (this is the DSVM server)

.PARAMETER baseurl
url from which to download data files (if any)

.PARAMETER username
login username for the server

.PARAMETER password
login password for the server

.PARAMETER sqlUsername
User to create in SQL Server

.PARAMETER sqlPassword
Password for the SQL User

#>
[CmdletBinding()]
param(
[parameter(Mandatory=$true, Position=1)]
[ValidateNotNullOrEmpty()] 
[string]$serverName,

[parameter(Mandatory=$true, Position=2)]
[ValidateNotNullOrEmpty()] 
[string]$username,

[parameter(Mandatory=$true, Position=3)]
[ValidateNotNullOrEmpty()] 
[string]$password

)

#$Prompt= if ($Prompt -match '^y(es)?$') {'Y'} else {'N'}

$Prompt = 'N'


####Just adding a blank line 

$SolutionName = "Hospital"
$SolutionFullName = "r-server-hospital-length-of-stay" 
$odbcName = 'CampOpt'
### DON'T FORGET TO CHANGE TO MASTER LATER...
$Branch = "dev" 
$InstallPy = 'Yes' ## If Solution has a Py Version this should be 'Yes' Else 'No' 
$setupLog = "c:\tmp\setup_log.txt"
Start-Transcript -Path $setupLog -Append
$startTime = Get-Date
Write-Host -ForegroundColor 'Green'  "  Start time:" $startTime 



$solutionTemplateName = "Solutions"
$solutionTemplatePath = "C:\" + $solutionTemplateName
$checkoutDir = $SolutionName
$SolutionPath = $solutionTemplatePath + '\' + $checkoutDir
$desktop = "C:\Users\Public\Desktop\"
$scriptPath = $SolutionPath + "\Resources\ActionScripts\"
$SolutionData = $SolutionPath + "\Data\"

##########################################################################
#Clone Data from GIT
##########################################################################


$clone = "git clone --branch $Branch --single-branch https://github.com/Microsoft/$SolutionFullName $solutionPath"

if (Test-Path $solutionTemplatePath) { Write-Host " Solution has already been cloned"}
ELSE {Invoke-Expression $clone}


#################################################################
##DSVM Does not have SQLServer Powershell Module Install or Update 
#################################################################



Write-Host " Installing SQLServer Power Shell Module or Updating to latest "

if (Get-Module -ListAvailable -Name SQLServer) {Update-Module -Name "SQLServer"}
 else 
    {
    Install-Module -Name SQLServer -Scope AllUsers -AllowClobber -Force
    Import-Module -Name SQLServer
    }



############################################################################################
#Configure SQL to Run our Solutions 
############################################################################################

#Write-Host -ForegroundColor 'Cyan' " Switching SQL Server to Mixed Mode"


### Change Authentication From Windows Auth to Mixed Mode 
Invoke-Sqlcmd -Query "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;" -ServerInstance "LocalHost" 

Write-Host -ForeGroundColor 'cyan' " Configuring SQL to allow running of External Scripts "
### Allow Running of External Scripts , this is to allow R Services to Connect to SQL (new feature on SQL 2017)
Invoke-Sqlcmd -Query "EXEC sp_configure  'external scripts enabled', 1"

### Force Change in SQL Policy on External Scripts 
Invoke-Sqlcmd -Query "RECONFIGURE WITH OVERRIDE" 
Write-Host -ForeGroundColor 'cyan' " SQL Server Configured to allow running of External Scripts "

Write-Host -ForeGroundColor 'cyan' " Restarting SQL Services "
### Changes Above Require Services to be cycled to take effect 
### Stop the SQL Service and Launchpad wild cards are used to account for named instances  
Stop-Service -Name "MSSQ*" -Force

### Start the SQL Service 
Start-Service -Name "MSSQ*"
Write-Host -ForegroundColor 'Cyan' " SQL Services Restarted"



$Query = "CREATE LOGIN $username WITH PASSWORD=N'$password', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
Invoke-Sqlcmd -Query $Query

$Query = "ALTER SERVER ROLE [sysadmin] ADD MEMBER $username"
Invoke-Sqlcmd -Query $Query

Write-Host " AdminUser Added as a SQL User "


Write-Host -ForegroundColor 'Cyan' " Done with configuration changes to SQL Server"


######################################################################## 
# If Prompted Install is Invoked, Prompt For SQLServer and dbName
########################################################################


$Query = "SELECT SERVERPROPERTY('ServerName')"
$si = invoke-sqlcmd -Query $Query
$si = $si.Item(0)



$ServerName = if ($Prompt -eq 'Y') {Read-Host  -Prompt "Enter SQL Server Name Or SQL InstanceName you are installing on"} else {$si}


WRITE-HOST " ServerName set to $ServerName"

$db = if ($Prompt -eq 'Y') {Read-Host  -Prompt "Enter Desired Database Base Name"} else {$SolutionName} 





######################################################################## 
#Decide whether we are using Trusted or Non Trusted Connections. ........Currently this does not work..............
########################################################################

$trustedConnection = "Y"
##$trustedConnection = if ($Prompt -eq 'y' -or $Prompt -eq 'Y') {"Y"} ELSE {Read-Host  -Prompt "Use Trusted Connection? Type in 'Y' or 'N'"}
##$UserName = if ($trustedConnection -eq 'n' -or $trustedConnection -eq 'N') {Read-Host  -Prompt "Enter UserName"}
##$Password = if ($trustedConnection -eq 'n' -or $trustedConnection -eq 'N') {Read-Host  -Prompt "Enter Password" -AsSecureString} 





##########################################################################

# Create Database and BaseTables 

#########################################################################

####################################################################
# Check to see If SQL Version is at least SQL 2017 and Not SQL Express 
####################################################################


$query = 
"select 
        case 
            when 
                cast(left(cast(serverproperty('productversion') as varchar), 4) as numeric(4,2)) >= 14 
                and CAST(SERVERPROPERTY ('edition') as varchar) Not like 'Express%' 
            then 'Yes'
        else 'No' end as 'isSQL17'"

$isCompatible = Invoke-Sqlcmd -ServerInstance $ServerName -Database Master -Query $query
$isCompatible = $isCompatible.Item(0)
if ($isCompatible -eq 'Yes' -and $InstallPy -eq 'Yes') {
    Write-Host " This Version of SQL is Compatible with SQL Py "

    ## Create Py Database
    Write-Host "  Creating SQL Database for Py "


    Write-Host -ForeGroundColor 'cyan' (" Using $ServerName SQL Instance") 

    ## Create PY Server DB
    $dbName = $db + "_Py"
    $SqlParameters = @("dbName=$dbName")

    $CreateSQLDB = "$ScriptPath\CreateDatabase.sql"

    $CreateSQLObjects = "$ScriptPath\CreateSQLObjectsPy.sql"
    Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the  $dbName database") 
    invoke-sqlcmd -inputfile $CreateSQLDB -serverinstance $ServerName -database master -Variable $SqlParameters


    Write-Host -ForeGroundColor 'cyan' (" SQLServerDB $dbName Created")
    invoke-sqlcmd "USE $dbName;" 

    Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the objects in the $dbName database")
    invoke-sqlcmd -inputfile $CreateSQLObjects -serverinstance $ServerName -database $dbName


    Write-Host -ForeGroundColor 'cyan' (" SQLServerObjects Created in $dbName Database")

 ## Create ODBC Connection for PowerBI to Use 
Add-OdbcDsn -Name $odbcName -DriverName "SQL Server Native Client 11.0" -DsnType 'System' -Platform '64-bit' -SetPropertyValue @("Server=$ServerName", "Trusted_Connection=Yes", "Database=$dbName") -ErrorAction SilentlyContinue -PassThru




}
Else 
{ "This Version of SQL is not compatible with Py , Py Code and DB's will not be Created "}




Write-Host "  Creating SQL Database for R "


Write-Host -ForeGroundColor 'cyan' (" Using $ServerName SQL Instance") 

$dbName = $db + "_R"


## Create RServer DB 
$SqlParameters = @("dbName=$dbName")

$CreateSQLDB = "$ScriptPath\CreateDatabase.sql"

$CreateSQLObjects = "$ScriptPath\CreateSQLObjectsR.sql"
Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the  $dbName database") 
invoke-sqlcmd -inputfile $CreateSQLDB -serverinstance $ServerName -database master -Variable $SqlParameters


Write-Host -ForeGroundColor 'cyan' (" SQLServerDB $dbName Created")
invoke-sqlcmd "USE $dbName;" 

Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the objects in the $dbName database")
invoke-sqlcmd -inputfile $CreateSQLObjects -serverinstance $ServerName -database $dbName


Write-Host -ForeGroundColor 'cyan' (" SQLServerObjects Created in $dbName Database")



Write-Host -ForeGroundColor cyan " Installing latest Power BI..."
# Download PowerBI Desktop installer
Start-BitsTransfer -Source "https://go.microsoft.com/fwlink/?LinkId=521662&clcid=0x409" -Destination powerbi-desktop.msi

# Silently install PowerBI Desktop
msiexec.exe /i powerbi-desktop.msi /qn /norestart  ACCEPT_EULA=1

if (!$?) {
    Write-Host -ForeGroundColor Red " Error installing Power BI Desktop. Please install latest Power BI manually."
}


##Create Shortcuts and Autostart Help File 
Copy-Item "$ScriptPath\SolutionHelp.url" C:\Users\Public\Desktop\
Copy-Item "$ScriptPath\SolutionHelp.url" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
Write-Host -ForeGroundColor cyan " Help Files Copied to Desktop"


###Copy PowerBI Reportt to Desktop 
Copy-Item  "$ScriptPath\*.pbix"  C:\Users\Public\Desktop\
Write-Host -ForeGroundColor cyan " PowerBI Reports Copied to Desktop"

###Configure Database for R 
Write-Host "  
        Configuring $SolutionName Solution for R
        "
  
$dbName = $db + "_R" 

## Create ODBC Connection for PowerBI to Use 
Add-OdbcDsn -Name $odbcName -DriverName "SQL Server Native Client 11.0" -DsnType 'System' -Platform '64-bit' -SetPropertyValue @("Server=$ServerName", "Trusted_Connection=Yes", "Database=$dbName") -ErrorAction SilentlyContinue -PassThru

##########################################################################
# Deployment Pipeline
##########################################################################


try
{

 Write-Host -ForeGroundColor 'cyan' (" Import CSV File(s).")
 $dataList = "LengthOfStay"

 
 # upload csv files into SQL tables
 foreach ($dataFile in $dataList)
 {
     $destination = $SolutionData + $dataFile + ".csv" 
     $tableName = $DBName + ".dbo." + $dataFile
     $tableSchema = $dataPath + "\" + $dataFile + ".xml"
     $dataSet = Import-Csv $destination
  Write-Host -ForegroundColor 'cyan' ("         Loading $dataFile.csv into SQL Table, this will take about 30 seconds per file....") 
     Write-SqlTableData -InputData $dataSet  -DatabaseName $dbName -Force -Passthru -SchemaName dbo -ServerInstance $ServerName -TableName $dataFile

     
  Write-Host -ForeGroundColor 'cyan' (" $datafile table loaded from CSV File(s).")
 }
}
catch
{
 Write-Host -ForegroundColor DarkYellow "Exception in populating database tables:"
 Write-Host -ForegroundColor Red $Error[0].Exception 
 throw
}
Write-Host -ForeGroundColor 'cyan' (" Finished loading .csv File(s).")

Write-Host -ForeGroundColor 'Cyan' (" Scoring and Training Data...")
$query = "EXEC Exec_Inital_RScoring"
#SqlServer\Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query -ConnectionTimeout  0 -QueryTimeout 0
SqlServer\Invoke-Sqlcmd -ServerInstance LocalHost -Database $dbName -Query $query -ConnectionTimeout  0 -QueryTimeout 0





###Conifgure Database for Py 
if ($isCompatible -eq 'Yes'-and $InstallPy -eq 'Yes')
{
    Write-Host "  
        Configuring $SolutionName Solution for Py
       # "
        $dbname = $db + "_Py"
       # $ActionScript = $solutionPath + "\SQLPy\LoadandTrainData.ps1 -ServerName $ServerName -dbName $dbName -Prompt $Prompt"
       # Invoke-Expression $ActionScript 

##########################################################################
# Deployment Pipeline
##########################################################################


   try
       {
    
        Write-Host -ForeGroundColor 'cyan' (" Import CSV File(s).")
        $dataList = "LengthOfStay"

		
		# upload csv files into SQL tables
        foreach ($dataFile in $dataList)
        {
            $destination = $SolutionData + $dataFile + ".csv" 
            $tableName = $DBName + ".dbo." + $dataFile
            $tableSchema = $dataPath + "\" + $dataFile + ".xml"
            $dataSet = Import-Csv $destination
         Write-Host -ForegroundColor 'cyan' ("         Loading $dataFile.csv into SQL Table, this will take about 30 seconds per file....") 
            Write-SqlTableData -InputData $dataSet  -DatabaseName $dbName -Force -Passthru -SchemaName dbo -ServerInstance $ServerName -TableName $dataFile
 
            
         Write-Host -ForeGroundColor 'cyan' (" $datafile table loaded from CSV File(s).")
        }
    }
    catch
    {
        Write-Host -ForegroundColor DarkYellow "Exception in populating database tables:"
        Write-Host -ForegroundColor Red $Error[0].Exception 
        throw
    }
    Write-Host -ForeGroundColor 'cyan' (" Finished loading .csv File(s).")
   
    Write-Host -ForeGroundColor 'Cyan' (" Scoring and Training Data...")
    $query = "Exec Exec_Inital_PyScoring"
    SqlServer\Invoke-Sqlcmd -ServerInstance LocalHost -Database $dbName -Query $query -ConnectionTimeout  0 -QueryTimeout 0
    #SqlServer\Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query -ConnectionTimeout  0 -QueryTimeout 0

      ##SqlServer\Invoke-Sqlcmd  -Database $DbName -Query "EXEC Execute_Yourself" -QueryTimeout 0 -ServerInstance $ServerName


}



$WsShell = New-Object -ComObject WScript.Shell
$shortcut = $WsShell.CreateShortcut($desktop + $checkoutDir + ".lnk")
$shortcut.TargetPath = $solutionPath
$shortcut.Save()


$endTime = Get-Date
Write-Host -ForegroundColor 'green'  " End time is:" $endTime


Write-Host -foregroundcolor 'green'(" Length of Stay Development Workflow Finished Successfully!")
$Duration = New-TimeSpan -Start $StartTime -End $EndTime 
Write-Host -ForegroundColor 'green'(" Total Deployment Time = $Duration") 
Stop-Transcript

##Launch HelpURL 
Start-Process "https://microsoft.github.io/r-server-hospital-length-of-stay/Typical.html"

## Close Powershell 
Exit-PSHostProcess
EXIT 