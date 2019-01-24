#Script to set VMQs only if Hyper-V is set to Switch Independent and Hyper-V#
#Script is only for Servers with 24 Physical Cores#
#Change the VMTeamName below to the name of the VMNEtwork TEam Adapter

$VMTeamName = $args[0]

[int]$TotalCores=0
$ProcDetails = Get-WmiObject –class Win32_processor | select *
foreach($CPU in $ProcDetails) {$TotalCores = $TotalCores + $CPU.NumberofCores}

[int]$MaxProc = $TotalCores / 2
[int]$SecondBaseNum = $Maxproc * 2


$TeamMemberArray = (Get-NetLbfoTeamMember -Team $VMTeamName).Name


Set-NetAdapterVmq -name $TeamMemberArray[0] -BaseProcessorNumber 0 -MaxProcessors $MaxProc -Enabled $True
Set-NetAdapterVmq -name $TeamMemberArray[1] -BaseProcessorNumber $SecondBaseNum -MaxProcessors $MaxProc -Enabled $True


Set-NetAdapterVmq -name $VMTeamName -Enabled $True
Write-Host "VMQ have been set to the following" -BackgroundColor DarkGreen
Write-Host $TeamMemberArray[0] "  BaseProcessorNumber = 0 MaxProcessors = " $MaxProc -BackgroundColor DarkGreen
Write-Host $TeamMemberArray[1] "  BaseProcessorNumber = " $SecondBaseNum " MaxProcessors = " $MaxProc -BackgroundColor DarkGreen

