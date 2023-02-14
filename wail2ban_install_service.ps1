################################################################################
#                        _ _ ____  _                 
#         __      ____ _(_) |___ \| |__   __ _ _ __  
#         \ \ /\ / / _` | | | __) | '_ \ / _` | '_ \ 
#          \ V  V / (_| | | |/ __/| |_) | (_| | | | |
#           \_/\_/ \__,_|_|_|_____|_.__/ \__,_|_| |_|
#
#           Script for installing wail2ban as service
#
#   Important!
#   In order for script to work, you have to download nssm from https://nssm.cc/download
#   and unzip 64bit or 32bit version of nssm.exe into nssm subfolder (located with this script file). 
#   
################################################################################

#paths and definitions
$installFolder = (Get-Location).Path
$installFolderShort = (New-Object -ComObject Scripting.FileSystemObject).GetFolder($installFolder).ShortPath
$powershellPath = (Get-Command powershell).Source 
$wail2banPath = $installFolderShort + "\wail2ban.ps1"
$nssmPath = $installFolder + "\nssm\nssm.exe"
$serviceName = "Wail2ban"


#run as administrator check
function administrator_check {
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "Script actions needs administrator privileges! Please run script as administrator."
        exit
    }
}

#help
if ($args -match "-help") {
    "`nwail2ban service install script   `n"
	"Script installs and uninstalls service via nssm tool"
	" "
	"Parameters: "
	" -install (or without parameter)	: installs and configures service"
	" -uninstall		                : Removes service"	
    " -help		                        : Help message"
	" "
}

#uninstall
if ($args -match "-uninstall") {
    administrator_check
    #check if service exists
    try {
        $checkService = (Get-Service -Name $serviceName -ErrorAction Stop)
    }
    catch {
        Write-Error $_" Service is not installed."
        exit
    }
    if ((($checkService).Status -eq "Running") -or (($checkService).Status -eq "Paused")) {
        Stop-Service -Name $serviceName -NoWait
    }
    & $nssmPath remove $serviceName confirm
}

#install via nssm
if (($args -match "-install") -or ($null -eq $args[0])) {
    administrator_check
    if ((Test-Path -Path $wail2banPath) -and (Test-Path -Path $nssmPath)) {
        & $nssmPath install $serviceName $powershellPath "-ExecutionPolicy Bypass -NoProfile -File $wail2banPath"
        Start-Sleep -Milliseconds 50
        & $nssmPath set $serviceName AppDirectory $installFolder
        Start-Sleep -Milliseconds 20
        Write-Host "Installation complete."
    }
    else {
        if (!(Test-Path -Path $nssmPath)) {
            Write-Error "Error: Could not create service because path to nssm '$nssmPath' does not exist. Please make sure that folder with nssm.exe is placed in same folder as wail2ban installation folder."
        }
        if (!(Test-Path -Path $wail2banPath)) {
            Write-Error "Error: Could not create service because wail2ban script path '$wail2banPath' does not exist. Please make sure that you are running the install script from same location as wail2ban install location."
        }
        exit
    }    
}

#v1.1 by Miroslav Holman, AdminIT