<# Set-ExecutionPolicy -ExecutionPolicy Bypass #>

<#

     .Synopsys
       Auto launch and minimize iracing supprting applications. 
      
     .Reqirements:
       CrewCheif:  http://thecrewchief.org
       MSVS2015:   https://www.microsoft.com/en-gb/download/details.aspx?id=48145
       vjoyconf:   https://sourceforge.net/projects/vjoystick/files/Beta%202.x/
       irffb:      https://github.com/nlp80/irFFB/releases
       VRSchool:   https://virtualracingschool.com/
       TradePaint: https://www.tradingpaints.com/
     
     .Howto
       Install any of the above modules for iracing or your race app
       Make a batch file to call this ps1 (powershell.exe -executionpolicy bypass -file "Path\To\iracing.ps1"
       NOTE:  Batch file MUST be called as admin, or executionpolcy will not get set.  
              You can disable this however I will not show you how as it can lead to unwanted risks. 
     

<# Application paths #>
$cheif      = <Path To: \Britton IT Ltd\CrewChiefV4\CrewChiefV4.exe">
$irffb      = <Path To: \irFFB.exe">
$VJoyConf   = <Path To: \vJoy\x64\vJoyConf.exe">
$vrschool   = <Path To: \VirtualRacingSchool\VRS-TelemetryLogger.exe">
$tradePaint = <Path To: \Rhinode LLC\Trading Paints\Trading Paints.exe">
<# Do not edit below here #> 

function Stop-Processes {
    param([parameter(Mandatory=$true)] $processName,$timeout = 5)
    $processList = Get-Process $processName -ErrorAction SilentlyContinue
    if ($processList) {
        # Try gracefully first
        $processList.CloseMainWindow() | Out-Null

        # Wait until all processes have terminated or until timeout
        for ($i = 0 ; $i -le $timeout; $i ++){
            $AllHaveExited = $True
            $processList | % {
                $process = $_
                If (!$process.HasExited){
                    $AllHaveExited = $False
                }                    
            }
            If ($AllHaveExited){
                Return
            }
            sleep 1
        }
        # Else: kill
        $processList | Stop-Process -Force        
    }
}


Stop-Processes "irFFB"       
Stop-Processes "vJoyconf"    
Stop-Processes "CrewChiefV4" 
Stop-Processes "VRS-TelemetryLogger"
Stop-Processes "Trading Paints"

Sleep 5

Start-Process $cheif
Start-Process $irffb
Start-Process $VJoyConf
Start-Process $tradePaint
Start-Process $vrschool


<# This section is not needed for anything other than to minimize the GUI's when launched #>
<#   I hated having all the windows on my screen when launched                            #>

$script:showWindowAsync = Add-Type –memberDefinition @” 
[DllImport("user32.dll")] 
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow); 
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru

#I dont care about these variables hence the overwrite
$irffb      = Get-Process -ProcessName irFFB
$VJoyConf   = Get-Process -ProcessName vJoyConf
$cheif      = Get-Process -ProcessName CrewChiefV4
$tradePaint = Get-Process -ProcessName "Trading Paints"
$vrschool   = Get-Process -ProcessName "VRS-TelemetryLogger"

Foreach ($pd in $irffb){$null = $showWindowAsync::ShowWindowAsync((Get-Process -PID $irffb.id).MainWindowHandle, 2) }
Foreach ($pd in $VJoyConf){$null = $showWindowAsync::ShowWindowAsync((Get-Process -PID $vJoyConf.id).MainWindowHandle, 2) }
Foreach ($pd in $cheif){$null = $showWindowAsync::ShowWindowAsync((Get-Process -PID $Cheif.id).MainWindowHandle, 2) }
Foreach ($pd in $TradePaint){$null = $showWindowAsync::ShowWindowAsync((Get-Process -PID $tradePaint.id).MainWindowHandle, 2) }
Foreach ($pd in $vrschool){$null = $showWindowAsync::ShowWindowAsync((Get-Process -PID $tradePaint.id).MainWindowHandle, 2) }
