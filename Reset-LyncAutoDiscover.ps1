Stop-Process -Name lync* -Force
Remove-Item -Path HKCU:\Software\Microsoft\Office\15.0\Lync\* -Recurse
Set-ItemProperty -Path HKCU:\Software\Microsoft\Office\15.0\Lync -Name ServerSipUri -Value ""
start-sleep -s 5
start-process -filepath "C:\Program Files (x86)\Microsoft Office\Office15\lync.exe"
start-process -filepath "C:\Program Files\Microsoft Office\Office15\lync.exe"
