# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-5.1
#Requires -version 5.1

<#
.SYNOPSIS
  Provisionning script for Windows dev VM
  Must be run as administrator

.DESCRIPTION
  This script will provision and configure Windows and Windows server VMs.

.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>

.INPUTS
  <Inputs if any, otherwise state None>

.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>

.NOTES
  Version:        1.0
  Author:         Patrick Meunier
  Creation Date:  27/07/18

.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"
$VerbosePreference = 'Continue'
$DebugPreference = 'Continue'

Install-PackageProvider -Name NuGet

# Install module from provider
Install-Module -name "PowershellLogging"
# Import necessary modules
Import-Module PowershellLogging

#----------------------------------------------------------[Declarations]----------------------------------------------------------

<#
Note - it is necessary to save the result of Enable-LogFile to a variable in order to
keep the object alive.  As soon as the $LogFile variable is reassigned or falls out of scope,
the LogFile object becomes eligible for garbage collection.
#>
$LogFile = Enable-LogFile -Path $env:UserProfile\Desktop\Provisionning.log
$ScriptVersion = "1.0"
$OsVersion = (Get-ComputerInfo).OsVersion
$OsType = (Get-ComputerInfo).OsProductType

#-----------------------------------------------------------[Functions]------------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Write script version to log
$ScriptVersion

# Write Powershell version to log file.
$PSVersionTable.PSVersion

# Install chocolatey package manager
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# To remove all the -y at the end of the chocolatey calls
choco feature enable -n allowGlobalConfirmation

# Install Boxstarter installation tool
cinst boxstarter

# Import Boxstarter module
Import-Module Boxstarter.Chocolatey

# Set execution policy with boxstarter
Update-ExecutionPolicy Unrestricted

### Windows OS configuration

## Enable Windows features

# Allows Remote Desktop access to machine and enables Remote Desktop firewall rule.
Enable-RemoteDesktop
# Sets options on the Windows Taskbar
Set-TaskbarOptions -Size Small -Lock -Dock Top -Combine Always -AlwaysShowIconsOn
# Sets options on the Windows Explorer shell
Set-ExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions 	-EnableShowFullPathInTitlebar
Disable-UAC

# For Windows 10 and Windows server 2016 and above.
if ($OsVersion -ge 10) {
  # Turns off the GameBar Tips of Windows 10 that are shown when a game - or what Windows 10 thinks is a game - is launched.
  Disable-GameBarTips
  # Disables the Bing Internet Search when searching from the search field in the Taskbar or Start Menu.
  Disable-BingSearch
  # Replace Command Prompt with Windows PowerShell in the menu when I right-click the lower-left corner or press Windows key+X
  Set-CornerNavigationOptions -EnableUsePowerShellOnWinX
  # To run docker containers
  cinst Microsoft-Hyper-V-All -source windowsFeatures

  if ($OsType == "Server") {
    # Turns off Internet Explorer Enhanced Security Configuration that is on by default on Server OS versions.
    Disable-InternetExplorerESC
  }
}

### Utilities

cinst googlechrome # browser
cinst filezilla # ftp client
cinst chocolateygui # GUI
cinst 7zip.install # compression utility
cinst fiddler # network trace
cinst firefox # browser
cinst git.install # versionning system
cinst keypirinha # app launcher and more...
cinst baretail # Live log viewer
cinst adobereader # pdf viewer
cinst cmder # terminal emulator
cinst poshgit # powershell environment for git
cinst gow # Unix command line utilities installer for Windows.


### Micro$oft tools
cinst visualstudiocode
cinst dotnet4.6.1
cinst dotnet4.7.1
cinst sysinternals
# Secure Git credential storage for Windows with support for Visual Studio Team Services,
#GitHub, and Bitbucket multi-factor authentication.
cinst Git-Credential-Manager-for-Windows

# Visual Studio code extensions
code --install-extension Shan.code-settings-sync
code --install-extension bierner.color-info
code --install-extension christian-kohler.path-intellisense
code --install-extension codezombiech.gitignore
code --install-extension emmanuelbeziat.vscode-great-icons
code --install-extension erikphansen.vscode-toggle-column-selection
code --install-extension michelemelluso.code-beautifier
code --install-extension mohsen1.prettify-json
code --install-extension oderwat.indent-rainbow
code --install-extension riccardoNovaglia.missinglineendoffile
code --install-extension shardulm94.trailing-spaces
code --install-extension wayou.vscode-todo-highlight

### Pin apps
Install-ChocolateyPinnedTaskBarItem "$env:programfiles\Google\Chrome\Application\chrome.exe"

# By default, only critical updates will be searched.
Install-WindowsUpdate -acceptEula

### Cleanup tasks

#  remove  the Previous Windows Installation / Upgrade files
Remove-WindowsUpgradeFiles -Verbose -Confirm:$false

$LogFile | Disable-LogFile
