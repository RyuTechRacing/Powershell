#Establish connection To Exchange session in Script
#$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://clt-ex3/PowerShell -Authentication Kerberos
#Import-PSSession $Session

#Force Stop action on failure, Used for the TRY section, will add Email notification at later date
$ErrorActionPreference = “Stop”
$Global:failedUser = ""

#Generate datestamp for completed imports
$global:date = (Get-Date).AddDays(-1).ToString('MM-dd-yyyy')

Function Shrink-Ray {
    Param($folder)
    ForEach ($PhotoFile in gci -af $folder){
        If (($photofile -like "*.jpg") -and ($PhotoFile.length -ge 10kb) -and ($PhotoFile.length -le 100kb)){
            Write-Host "Length: $($photofile.length /1kb)"
            $JPGFile = $photofile.FullName
            $BMPFile = $photofile.fullname +".bmp"

            #Load required assemblies and get object reference 
            [Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”)
        
            $i = new-object System.Drawing.Bitmap($JPGFile)
            #Display image properties including height and width 
            # $i; 
            #Save with the image in the desired format 
            $i.Save($BMPFile,“bmp”)
            $I.Dispose()
            $i = $null

            move-item $PhotoFile.FullName C:\temp\photo\done\$($Photofile.name)

            $o = new-object System.Drawing.Bitmap($BMPFile)
            $o.Save($JPGFile,“jpeg”)
            $o.dispose()
            $o = $null
            rm $BMPFile
        }
    }
}
Function Import-photo {
    param($Folder) #pull variable
        ForEach ($PhotoFile in gci -af $folder){
        $User = '' + $PhotoFile.Name.substring(0, $PhotoFile.Name.Length - 4) + ''
         Try { Import-RecipientDataProperty -Identity $User -Picture -FileData ([Byte[]]$(Get-Content -Path $PhotoFile.Fullname -Encoding Byte -ReadCount 0)) -whatif}
        Catch{
 
           #Check File resolution
           [Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”);
            $PhotoStats = New-Object System.Drawing.Bitmap($PhotoFile.fullname);
            $PW = $photostats.Width
            $PH = $photostats.Height
            If ($PW -gt 96 -or $PH -gt 96) {$rezo = "**Photo Resoloution: Photo to Big ($PH x $PW)`r`n"}
            $photostats.Dispose()

           #Check to see if User has a mailbox
            Try{(Get-Mailbox $user).servername}Catch [System.Management.Automation.RemoteException] {$Mail = "Mail Server: $user's Mailbox does not Exist`r`n"}

           #Determine size of JPG
            $presize = (Get-Item $photofile.fullname).Length
            If($presize -gt 10kb){ 
                        $presize = "{0:N2}" -f ((Get-Item $photofile.fullname).Length /1kb)
                        $size = "**Photo Size: Larger than 10kb ($($presize)KB)`r`n"}Else{$size=$null}
            
           #Build Email String
            $Global:Body += "User: $user`r`n$rezo$size$Mail`r`n"
            Write-Warning `r`n$Global:Body #output test
            $rezo = ""
            $mail = ""
            $size = ""
           #Continue on to next sequance, Will continue to build Failed User list
		    Continue
	    }
        
   }
}

Shrink-Ray -Folder "C:\temp\Photo"
Import-photo -Folder "C:\temp\photo"

Send-MailMessage -From "Server@domain.com" -To "User@domain.com" -SmtpServer smtp.domain.com -Subject "Results from AD Photo Imports - $global:date" -Body $Global:Body