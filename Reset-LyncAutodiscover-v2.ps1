#kill Outlook dependent Processes

function Kill-Office{
    Proc-Killer -proc "outlook*"
    Proc-Killer -proc "lync*" 
    Get-Process Shoretel | Stop-Process -force -ErrorAction SilentlyContinue
    Get-Process ucmapi | Stop-Process $_ -force -ErrorAction SilentlyContinue
    Get-Process ummapi | Foreach-Object { $_.CloseMainWindow() } | Stop-Process $_ -force -ErrorAction SilentlyContinue
    
    Start-sleep -s 5
}

Function Proc-Killer{
 param($proc)
$isopen = Get-Process $Proc
if($isopen = $null){
    # Outlook is already closed run code here:
    }
else {
     $isopen = Get-Process $Proc

     # while loop makes sure all outlook windows are closed before moving on to other code:
         while($isopen -ne $null){
            Get-Process $Proc | ForEach-Object {$_.CloseMainWindow() | Out-Null }
            sleep 5
            If(($isopen = Get-Process $Proc) -ne $null){
            Write-Host "Outlook is Open.......Closing Outlook"
                $wshell = new-object -com wscript.shell
                if ($proc -like "outlook*"){$wshell.AppActivate("Microsoft Outlook")}
                if ($proc -like "lync*"){$wshell.AppActivate("Microsoft Lync")}
                $wshell.Sendkeys("%(Y)")
            $isopen = Get-Process $Proc
            }
        }
        #Outlook has been closed run code here:
    }
    }


Function Purge-Files{
    #Clean up address book and caches
    Remove-Item  "$env:USERPROFILE\AppData\Local\Microsoft\Outlook\Offline Address Books\" -force -recurse -ErrorAction SilentlyContinue
    Remove-Item  "$env:USERPROFILE\AppData\Local\Microsoft\Outlook\RoamCache" -force -recurse -ErrorAction SilentlyContinue
    Remove-Item  "$env:USERPROFILE\AppData\Local\Microsoft\Outlook\*.tmp" -force -recurse -ErrorAction SilentlyContinue

    #clean up Registry
    Remove-Item -Path HKCU:\Software\Microsoft\Office\15.0\Lync\* -Recurse -ErrorAction SilentlyContinue
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Office\15.0\Lync -Name ServerSipUri -Value "" -ErrorAction SilentlyContinue
}

Function Restore-Office{
    #check if Exec exists before starting
    If (Test-path "C:\Program Files (x86)\Microsoft Office\Office15\outlook.exe"){& "C:\Program Files (x86)\Microsoft Office\Office15\outlook.exe"}
    If (Test-path "C:\Program Files\Microsoft Office\Office15\outlook.exe"){& "C:\Program Files\Microsoft Office\Office15\outlook.exe"}
    
    If (Test-path "C:\Program Files (x86)\Microsoft Office\Office15\lync.exe"){& "C:\Program Files (x86)\Microsoft Office\Office15\lync.exe"}
    If (Test-path "C:\Program Files\Microsoft Office\Office15\lync.exe"){& "C:\Program Files\Microsoft Office\Office15\lync.exe"}
    }


Kill-Office
Purge-Files
Restore-Office