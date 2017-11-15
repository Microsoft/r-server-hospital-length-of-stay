﻿<#
.SYNOPSIS
Powershell script for setting up the solution template. 

.DESCRIPTION
This script checks out the solution from github and deploys it to SQL Server on the local Data Science VM (DSVM).

.WARNING: This script is only meant to be run from the solution template deployment process. if you want to set the database back to the intial state 
run  Invoke-Expression C:\Solutions\Hospital\Resources\ActionScripts\createdatabase.ps1 from a elevated PS window. 
#>
$setupLog = "c:\tmp\setup_log.txt"
Start-Transcript -Path $setupLog -Append
$startTime= Get-Date
Write-Host -ForegroundColor 'Green'  "  Start time:" $startTime 


$solutionTemplateName = "Solutions" #change this back to Solutions after done testing 
$solutionTemplatePath = "C:\" + $solutionTemplateName
$checkoutDir = "Hospital"
$SolutionPath = $solutionTemplatePath +'\' + $checkoutDir
$desktop = "C:\Users\Public\Desktop\"


### DON'T FORGET TO CHANGE TO MASTER LATER...

if (Test-Path $solutionTemplatePath) 
{
Write-Host " Solution has already been cloned"
}
ELSE   
{
    git clone  --branch dev --single-branch https://github.com/Microsoft/r-server-hospital-length-of-stay $solutionPath
}

##DSVM Does not have SQLServer Powershell Module , this will try and install it if it is not present it will work , if it is already there it will error out 
Write-Host " Installing SQLServer Power Shell Module , if it is already installed a warning will be displayed , this is OK........."
Install-Module -Name SQLServer -Scope AllUsers -AllowClobber -Force
Import-Module -Name SQLServer

###Configure Database for R 
Write-Host "  Configuring Solution for R"
$ActionScripts = $SolutionPath + "\Resources\ActionScripts\CreateDatabase.ps1"
Invoke-Expression $ActionScripts

###Conifgure Database for Py 
Write-Host "  Configuring Solution for Py"
$ActionScripts = $SolutionPath + "\Resources\ActionScripts\CreateDatabasePy.ps1"
Invoke-Expression $ActionScripts

$WsShell = New-Object -ComObject WScript.Shell
$shortcut = $WsShell.CreateShortcut($desktop + $checkoutDir + ".lnk")
$shortcut.TargetPath = $solutionPath
$shortcut.Save()


$endTime= Get-Date
Write-Host -ForegroundColor 'green'  " End time is:" $endTime


Write-Host -foregroundcolor 'green'(" Length of Stay Development Workflow Finished Successfully!")
$Duration = New-TimeSpan -Start $StartTime -End $EndTime 
Write-Host -ForegroundColor 'green'(" Total Deployment Time = $Duration") 
Stop-Transcript
Exit-PSHostProcess
EXIT 