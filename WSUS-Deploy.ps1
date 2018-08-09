<# Powershell Deployment Configured for WSUS Servers
Author: Ryan Thompson
Date: 5/21/18
Pre-requirements: windows server 2012 R2 with a D drive that has minimum 200GB space

Notes:
    Goal - Automate deployment and configuration of WSUS for servers.   This will remove the requirement for a single person to struggle with the deployment

HowTo:
     Set Variables to fit your environment:
     Drive Letter: Install Drive NO Special Characters
     UpStreamServer: Set FQDN of Upstream Server
     Port: Change if Not using Genric port
     SyncTime: When do you want Sync to Trigger first
     SyncPerDay: How Often to Sync with master
     ServiceAccount: Account name to run Maintenance Script with
     CleanupPS1: A generic Ps1 Cleanup script.  (One can be found here: https://gallery.technet.microsoft.com/scriptcenter/WSUS-Maintenance-w-logging-d507a15a)
     CleanupXML: An Export from a server. (Steps can be found here: https://www.petri.com/export-scheduled-tasks-using-powershell)

    Running Code:
        For Full Automation, Type Install-WSUS-Service
        For Targeted Deployment use the following:

            Install-Wsus-Features - Install Core features and roles - NO Configuration
            Config-Downstream     - Defines settings for Downstream server, Starts Initial Syncronization to Upstream Server defined
            Config-Install        - Set WSUS folder, Copy Maintenance Scripts, Start Postinstall tasks
            Config-Maintenance    - Configures Scheduled Task for maintenance NOTE: Code will prompt for Password


Change Log:
    Date - Change List
    5/22/18 - Added in Install-WSUS-Service Function

ToDo List:
    Determine if Config-Downstream Supports moving WSUS folder path
    Continue to define hardcoded variables into global variables
#>


#<Variables>
$DriveLetter = "<Drive letter for WSUS>"
$Upstreamserver = "<FQDN WSUS Upstream Server>"
$port = 8530
$syncTime = "20:00:00" #Format as HH:MM:SS
$SyncPerDay = "3"

#These 3 files are used for adding the maintenance script for cleanup.
$CleanUpEX1 = "<Folder Path>\Run First - msodbcsql.msi"
$CleanUpEX2 = "<Folder Path>\Run Second - MsSqlCmdLnUtils.msi"
$CleanUpPS1 = "<Folder Path>\Clean-WSUS.ps1"
#<End Variables>

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!$isadmin) {
    Write-Host "Please launch Powershell as Administrator (right click, Run as admin) `r`n"
    Return #kill script with out closing UI
}


Function Install-WSUS-Service {
    Install-WSUS-Features
    Configure-Downstream
    Configure-Install
    Configure-Maintenance
}


Function Install-WSUS-Features {
    Install-WindowsFeature -Name UpdateServices, UpdateServices-WidDB, UpdateServices-Services, UpdateServices-RSAT, UpdateServices-API, UpdateServices-UI
}

Function Configure-Downstream {
    <# Code acquired from here: https://gallery.technet.microsoft.com/scriptcenter/48e39caa-7cfc-439b-86e7-45618f25ee85 #>
    # Configure WSUS Replica Server
    #------------------------------
    # Setup Error Logging
    $erroractionpreference="Continue"
    $error.clear()

    #------------------------------
    # Load the WSUS assenbly DLL and assign it to the $wsus variable
    [reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
    $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();
    $wsusConfig = $wsus.GetConfiguration()               # Assign the wsus configuration property objects to the $wsusconfig variable
    $wsusConfig.SyncFromMicrosoftUpdate=$false           # Set the WSUS Update Source to goto another WSUS server rather than Microsoft
    $wsusConfig.UpstreamWsusServerName=$UpstreamServer   # Set the Upstream Server Name - Replace Server1 with your Primary WSUS server name
    $wsusConfig.UpstreamWsusServerPortNumber=$port       # Set the Upstream server Port Number - Replace 8530 with your port number
    $wsusConfig.IsReplicaServer=$True                    # Set the WSUS Server as a Replica of its Upstream Server
    $wsusConfig.TargetingMode="Client"                   # Set client side targeting for group membership
    $wsusConfig.Save()                                   # Save the configuration
    $wsusSub = $wsus.GetSubscription()                   # Assign the wsus Subscription Property objects to the $wsussub variable
    $wsusSub.SynchronizeAutomatically=$True              # Set the WSUS Server Syncronisation to Automatic
    $wsusSub.SynchronizeAutomaticallyTimeOfDay=$syncTime # Set the WSUS Server Syncronisation Time
    $wsusSub.NumberOfSynchronizationsPerDay=$SyncPerDay  # Set the WSUS Server Syncronisation Number of Syncs per day
    $wsusSub.Save()                                      # Save the Syncoronisation Configuration
    
    Write-Host "Starting First Sync";
    $wsusSub.StartSynchronization()                      # Start a Sync

    if ($error.count -ne 0)
     {
         write-host "Errors: $error.count"
         return
     }
     write-host "Results of first Sync:"
     (Get-WsusServer).GetSubscription().GetLastSynchronizationInfo()
 }

Function Configure-Install {
    $InstallPath = $DriveLetter + ':\wsus'
    New-Item -ItemType directory -Path $InstallPath -Force
    New-Item -ItemType directory -Path $InstallPath\Scripts -Force

    & 'C:\Program Files\Update Services\Tools\WsusUtil.exe' postinstall CONTENT_DIR=$InstallPath

}

Function Configure-Maintenance {
    $InstallPath = $DriveLetter + ':\wsus'
    Copy-item -path $CleanUpEX1 -Destination "$InstallPath\Scripts\Run First - msodbcsql.msi" -Force
    Copy-item -path $CleanUpEX2 -Destination "$InstallPath\Scripts\Run Second - MsSqlCmdLnUtils.msi" -Force
    Copy-item -path $CleanUpPS1 -Destination "$InstallPath\Scripts\Clean-WSUS.ps1" -Force

    $App1Path = "$InstallPath\Scripts\Run First - msodbcsql.msi"
    $App2Path = "$InstallPath\Scripts\Run Second - MsSqlCmdLnUtils.msi"
    $Arglist1 = @("/i `"$App1Path`"","/qn","/norestart","IACCEPTMSODBCSQLLICENSETERMS=YES")
    $Arglist2 = @("/i `"$App2Path`"","/qn","/norestart","IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES","/log C:\temp\Log.log")

    Write-host "Installing MSODBCSQL.msi"
    Start-Process "msiexec.exe" -ArgumentList $arglist1 -Wait -NoNewWindow
    start-sleep -seconds 5

    Write-host "Installing MsSqlCmdLnUtils.msi"
    Start-Process "msiexec.exe" -ArgumentList $arglist2 -Wait -NoNewWindow
    if (!(test-path -path "C:\tmp" -pathtype container)) {New-Item -ItemType directory -Path "C:\tmp" -force}
    $installLog = "c:\tmp\log.log"
    Get-Content -Tail 10 $installLog


    $env:Path += ";C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\"
    $MaintenancePath = "$installPath\Scripts\Clean-Wsus.ps1"
    Invoke-Expression "& `"$MaintenancePath`" -Firstrun"
