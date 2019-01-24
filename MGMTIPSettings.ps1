
#Set MGMT IP using PSExec

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Confirm:$false

$MGMTDetails =  Import-Csv C:\Windows\Temp\Networking.csv | Where-Object {$_.teamname -like "*MGMT*"}
$ServerNetworkAdapters = Get-NetAdapter

#Get MGMT Net Adaptersd
$ArrayMGMTTeam =@()
foreach ($SName in $ServerNetworkAdapters) {if ($SName.Name -like "*MGMT*") {$ArrayMGMTTeam += $SName.Name }} 

                # Remove any IP settings on MGMT Network Adapters
               
Try
{
Remove-NetIPAddress -InterfaceAlias $ArrayMGMTTeam[0] -PrefixOrigin Manual -Confirm:$false -ErrorAction Stop
}
Catch
{
Write-Host "Did not Find any settings to remove" 
}

Try
{
Remove-NetRoute -InterfaceAlias $ArrayMGMTTeam[0] -Confirm:$false -ErrorAction Stop
}
Catch
{
Write-Host "Did not Find any settings to remove" 
}

Try
{
Set-DnsClientServerAddress -InterfaceAlias $ArrayMGMTTeam[0] -ResetServerAddresses -Confirm:$false -ErrorAction Stop
}
Catch
{
Write-Host "Did not Find any settings to remove" 
}

Try
{
Set-NetIPAddress -InterfaceAlias $ArrayMGMTTeam[0] -Dhcp Enabled -Confirm:$false -ErrorAction Stop
}
Catch
{
Write-Host "Did not Find any settings to remove" 
}

Try
{
Remove-NetIPAddress -InterfaceAlias $ArrayMGMTTeam[1] -PrefixOrigin Manual -Confirm:$false -ErrorAction Stop
}
Catch
{
Write-Host "Did not Find any settings to remove" 
}

Try
{
Remove-NetRoute -InterfaceAlias $ArrayMGMTTeam[1] -Confirm:$false -ErrorAction Stop
}
Catch
{
Write-Host "Did not Find any settings to remove" 
}

Try
{
Set-DnsClientServerAddress -InterfaceAlias $ArrayMGMTTeam[1] -ResetServerAddresses -Confirm:$false -ErrorAction Stop
}
Catch
{
Write-Host "Did not Find any settings to remove" 
}

Try
{
Set-NetIPAddress -InterfaceAlias $ArrayMGMTTeam[1] -Dhcp Enabled -Confirm:$false -ErrorAction Stop
}
Catch
{
Write-Host "Did not Find any settings to remove" 
}
                #Create MGMT Team, Set Ip, DNS
                New-NetLbfoTeam -Name $MGMTDetails.teamname -TeamingMode SwitchIndependent -LoadBalancingAlgorithm Dynamic -TeamMembers $ArrayMGMTTeam[0],$ArrayMGMTTeam[1] -Confirm:$false
                New-NetIPAddress -InterfaceAlias $MGMTDetails.teamname -AddressFamily IPv4 -IPAddress $MGMTDetails.ipaddress -PrefixLength $MGMTDetails.subnet -DefaultGateway $MGMTDetails.gateway -Confirm:$false
                Set-DnsClientServerAddress -InterfaceAlias $MGMTDetails.teamname -ServerAddresses ($MGMTDetails.dns1,$MGMTDetails.dns2) -Confirm:$false
                ipconfig /flushdns
                ipconfig /registerdns 
                





