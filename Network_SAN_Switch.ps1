
#Script Creates Virtual Network Switch & Virtual Fiber Channel SAN#

#First we will Create one Virtual Network Switch#
#Change VMTeamName to the name of the VMNetwork Team Network you gave when creating the team#
#Change VMSwitchName to a unique name for the cluster#


[string]$CompName = $args[0]
$VMSANName = $args[1]
$VMSwitchName = $args[2]
$VMTeamName = $args[3]




#Create Virtual Newwork Switch#
Set-ExecutionPolicy Unrestricted
Import-Module Hyper-V
New-VMSwitch -Name $VMSwitchName -NetAdapterName $VMTeamName -AllowManagementOS $false
Write-Host "Virtual Switch Created, you can use Get-VMSwitch and Check Hyper-V Managment to Confirm" -BackgroundColor DarkGreen


#Change VMSANName below to the name of the Virtual Fiber Channel SAN that you want, make sure to end with 0#


#Loop to create a Virtual Fiber Channel SAN for each Adapter#
If ((Get-VMSan).count -eq 0)
{
$i = 0
Get-InitiatorPort -ConnectionType FibreChannel | ForEach-Object{
        $i++
        New-VMSan -Name "$VMSANName$i" -HostBusAdapter $_
    }
}
else
{
    # do nothing
}
Write-Host "Virtual Fiber Channel SAN Created, you can use Get-VMSAN and Check Hyper-V Managment to Confirm" -BackgroundColor DarkGreen





