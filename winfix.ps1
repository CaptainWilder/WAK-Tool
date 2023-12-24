##############################################
#           Wilder Army Knife                #
#          Fix Windows n shit                #
##############################################

###How to Properly run: 
#Open Powershell
#cd to directory where winfix.ps1 lives
#PowerShell -ExecutionPolicy Bypass -File ./winfix.ps1

###Perms Check
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Warning "You do not have Administrator rights to run this script! Please re-run as Administrator!"
    break
}


###Delete Windows Temp Files
Write-Output "Deleting Windows Temp Files..."
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue


###Delete Windows Update Download Files
Write-Output "Deleting Windows Update Download Files..."
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue


###SFC Scan
Write-Output "Running System File Checker..."
sfc /scannow


###DISM
Write-Output "Starting Deployment Image Servicing and Management tool repair..."
DISM /Online /Cleanup-Image /RestoreHealth


###Defrag
Write-Output "Finding Windows Volume"
$windowsDrive = (Get-WmiObject -Class Win32_OperatingSystem).SystemDrive #find windows volume
if ($windowsDrive -ne "C:") {
    Write-Output "Windows is not installed on C:. It is installed on $windowsDrive."
} else {
    Write-Output "Windows is installed on C: drive."
}
Write-Output "Defragmenting the Windows drive ($windowsDrive)..."
Optimize-Volume -DriveLetter $windowsDrive.Trim(":") -Defrag -Verbose
Write-Output "Defragmentation completed for the Windows drive ($windowsDrive)."


###DNS & TCP/IP reset
Write-Output "Flushing DNS and Resetting TCP/IP..."
ipconfig /flushdns
netsh int ip reset
Write-Output "Resetting Winsock..."
netsh winsock reset


###CHKDSK
Write-Output "Creating task for disk check..."
chkdsk /f /r

###FINISH
Write-Output "Windows repair tasks have been completed."
$userChoice = Read-Host "Do you want to reboot now? (Y/N)"
if ($userChoice -eq 'Y') {
    Write-Output "System will reboot in 10 seconds..."
    Start-Sleep -Seconds 10
    Restart-Computer
} elseif ($userChoice -eq 'N') {
    Write-Output "Please manually reboot the system at your earliest convenience."
} else {
    Write-Output "Invalid choice. Please manually reboot the system."
}
