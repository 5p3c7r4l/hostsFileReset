$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$PSNativeCommandUseErrorActionPreference = $true
$host.ui.rawui.backgroundcolor = "black"
clear-host

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-Not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    [string] $answer = Read-Host "This script needs to be ran as administrator, would you like to switch ? (Y/n)"
    [string] $curScript = $MyInvocation.MyCommand.Path
    switch ($answer.toLower())
    {
    "y"{
        Write-Host "INFO: You will be prompted with 2 requests, accept both to start the script" -ForegroundColor Green
        Write-Host "1st Prompt: Allows script to be run through a terminal (aka: change execution policy to unrestricted)" -ForegroundColor Blue
        Write-Host "2nd Prompt: Starts the script itself" -ForegroundColor Blue
        pause
        Start-Process powershell -Verb RunAs "Set-ExecutionPolicy -ExecutionPolicy Unrestricted"
        Start-Process powershell -Verb RunAs "powershell -NoExit -NoProfile -Command $curScript";
        }
        Default {
        Write-Host "ERROR: Permission Denied" -ForegroundColor Red
        exit
        }
    }
}else {Write-Host "INFO: New instance as administrator" -ForegroundColor Blue}
if (-Not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {Write-Host "INFO: Closing first instance of the script" -ForegroundColor Green 
    exit
}

function endingSequence{
    [string] $curPolicyExe = Get-ExecutionPolicy
    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        if ($curPolicyExe.toLower() -eq "unrestricted"){
        Write-Host "INFO: This last terminal window sets the script execution back to its default state (aka: change execution policy to restricted)" -ForegroundColor Green
        pause
        Start-Process powershell -Verb RunAs "Set-ExecutionPolicy -ExecutionPolicy Restricted"
        Start-Sleep -Seconds 2
        }
        Get-Process -ProcessName powershell | Stop-Process
        exit
    }
}

try{
    [string] $curDir = $ENV:windir+"\System32\Drivers\Etc\"
    [int] $flag = 0
    if (Test-Path -Path "$curDir") {
        $flag = 1
        Write-Host "File found, changing the host file (flag:$flag)"    
    } else {
        Write-Host "Couldn't find the etc directory automatically, input the directory yourself ? (Y/n)"
        [string] $answer = Read-Host
        switch ($answer.toLower()){
            "n" {
                $flag = 2
                Write-Host "ERROR: Couldn't find the etc directory of Windows (%WinDir%\System32\Drivers\Etc) flag:$flag" -ForegroundColor Red
                endingSequence
                }
            "y" {
                $flag = 0
                $answer = Read-Host "input the PATH of your hosts file (default:%WinDir%\System32\Drivers\Etc)"
            }
            Default {endingSequence}
        }
        if (-Not (Test-Path -Path $answer)) {
            $flag = 2
            Write-Host "ERROR: Couldn't find the etc directory of Windows (%WinDir%\System32\Drivers\Etc) flag:$flag" -ForegroundColor Red
            endingSequence
        }
        $curDir = $answer
    }
    $defaultHostsValues = @'
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

# localhost name resolution is handled within DNS itself.
#    127.0.0.1       localhost
#    ::1             localhost
'@
    
    if (-Not (Test-Path -Path "$curDir\hosts")){
        Write-Host "WARNING: No hosts file was found, do you want to create one ? (Y/n)" -ForegroundColor Yellow
        [string] $answer = Read-Host
        switch ($answer.toLower()){
            "n" {
                Write-Host "INFO: No further operations, closing the script" -ForegroundColor Green
                endingSequence
            }
            "y" {
                Write-Host "INFO: Proceeding to create a default hosts config" -ForegroundColor Green
                New-Item "$curDir\hosts"
                Add-Content -Path "$curDir\hosts" -Value $defaultHostsValues
                endingSequence
            }
            Default {endingSequence}
        }
    }
    Copy-Item "$curDir\hosts" -Destination "$curDir\hosts.old"
    Remove-Item "$curDir\hosts"
    New-Item "$curDir\hosts"
    Add-Content -Path "$curDir\hosts" -Value $defaultHostsValues
    Write-Host "SUCCESS: The hosts file has successfully been changed" -ForegroundColor Blue
    endingSequence
}
catch{
    Write-Host "ERROR: Unable to start the script: " + $_.Exception.ToString()
    pause
}
