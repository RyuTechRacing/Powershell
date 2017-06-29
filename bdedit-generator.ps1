Function Make-bdeditCode {
<#
	.SYNOPSIS
		Converts CSV to DBEDIT Readable export for Bulk importing of checkpoint firewall ip addresses

	.DESCRIPTION
		Converts CSV to DBEDIT Readable export for Bulk importing of checkpoint firewall ip addresses.
        CSV must contain the following headers "Name,Type,IP,Comments", these are the 4 fields used in the bdedit process.
        Example of CSV Formatting:
               
                Name,Type,IP,Comments
                Test_H,Host Node,127.0.0.1,No place like home
                Test_R,Address Range,127.0.0.1 to 127.0.0.254,Home home on the range
               
        BDEDIT does not like most special characters in the notes section.
        This code does not clean out illegial characters from the notes

	.NOTES
		Author: Ryan Thompson

	.EXAMPLE
		Make-bdeditCode -csvpath .\iplist.csv  -objgroup FTP_Clients -outputpath c:\temp\

		Description
		-----------
		    CSVPath: Path and file name of your csv file
            OutputPath: Folder path to write export to
            ObjGroup: Group name to assign IPs to 

    .VERSON
        Current: V1.0

	.INPUTS
		None. You cannot pipe objects to this script.

	#>

    Param(
		[parameter(Mandatory = $true)]
	    $csvpath,$outputPath,$ObjGroup
    )
    If(!$(gci $csvpath -ErrorAction SilentlyContinue)){write-host "Missing/Incorrect File Path"; break}
    $iplist = Import-csv  $csvpath
    $OutfileName = "$($Outputpath)\Firewall.txt"
    Write-Host "Exporting to $OutfileName"
    IF(!$(gci $outputPath -ErrorAction SilentlyContinue)){New-Item -ItemType directory -Path $outputPath |Out-Null}
    Out-File -Encoding ascii -file $($OutfileName) #Create the File object, but no writting
    Foreach ($Client in $iplist){
        If ($client.Type -eq "Address Range"){
            $tempIP = $client.IP.replace(" to ",",")
            $A1,$A2 = $tempIP.split(",")
            Write-Output “modify network_objects $($Client.Name) ipaddr_first $($A1.trim())" | Out-File -Encoding ascii -Append $($OutfileName)
            Write-Output “modify network_objects $($Client.Name) ipaddr_last $($A2.trim())" | Out-File -Encoding ascii -Append $($OutfileName)
            Write-Output “modify network_objects $($Client.Name) comments $($client.Comments)" | Out-File -Encoding ascii -Append $($OutfileName)
            Write-Output “addelement network_objects $($ObjGroup) '' network_objects:$($client.Name)” | Out-File -Encoding ascii -Append $($OutfileName)
            Write-Output "update network_objects $($Client.Name)" | Out-File -Encoding ascii -Append $($OutfileName)
        }
        Else {
            Write-output “create host_plain $($Client.Name)”| Out-File -Encoding ascii -Append $($OutfileName)
            Write-output “modify network_objects $($Client.Name) ipaddr $($Client.IP.trim())” | Out-File -Encoding ascii -Append $($OutfileName)
            Write-output “modify network_objects $($Client.Name) comments $($Client.Notes)” | Out-File -Encoding ascii -Append $($OutfileName)
            Write-output “addelement network_objects $($ObjGroup) '' network_objects:$($client.Name)” | Out-File -Encoding ascii -Append $($OutfileName)
            Write-Output "update network_objects $($Client.Name)" | Out-File -Encoding ascii -Append $($OutfileName)
        }
    }
    Write-Output "quit -update_all" | Out-File -Encoding ascii -Append $($OutfileName)
}
