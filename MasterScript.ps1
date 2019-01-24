
#Remote Hyper-V Post Deployment
#Remote Master Script to Call other Scritps on Remote Machine
#Set the IP for OneVIew Below

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope CurrentUser

$a = new-object -comobject wscript.shell

#Function to check if computer is ONline.
Function ComputerOnline
{

Test-Connection -ComputerName $args[0] -Quiet 

}


#Get Host Name
Write-Host "******************************************************************" -BackgroundColor DarkGreen
Write-Host "**1. Make sure you are running Powershell as Domain Administrator*" -BackgroundColor DarkGreen
Write-Host "**2. Make sure you Admin rights on remote servers*****************" -BackgroundColor DarkGreen
Write-Host "**3. Make sure you have all the scripts in the same Folder********" -BackgroundColor DarkGreen
Write-Host "**4. Confirm Networking and VSwitch Excel files are complete******" -BackgroundColor DarkGreen
Write-Host "******************************************************************" -BackgroundColor DarkGreen
$HostName = Read-Host -Prompt 'Enter name of Hyper-V Host, It should be the same as ONEVIEW' 


#Get Credentails 
Write-Host "Enter OneView Credentials in 5 Seconds" -BackgroundColor DarkGreen
Start-Sleep -s 5
$Creds = Get-Credential -Message "Enter OneView Credentails"
[String]$PlainPassword = $Creds.GetNetworkCredential().Password
[String]$PlainUserName = $Creds.UserName


#Turn off Firewall
Write-Host "Turning Firewall Off" -BackgroundColor DarkGreen
Invoke-Command -ComputerName $HostName -ScriptBlock {Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled False}


#Confrim Server is online
If ((ComputerOnline $HostName) -eq $false)
    {
    Write-Host "*HOST NOT ONLINE - CHECK AND RUN AGAIN*" -BackgroundColor "red"
    Exit
    }
Write-Host "Host is Online" -BackgroundColor DarkGreen

#Connect to Oneview and grab MAC/Network settings.
Write-Host "Connecting to OneView" -BackgroundColor DarkGreen
Import-Module .\POSH-HPOneView-2.0.139.0\HPOneView.200.psm1 -Force
Try
{
$OVConnect = Connect-HPOVMgmt -HostName "x.x.x.x" -UserName $PlainUserName -password $PlainPassword -ErrorAction Stop
}
Catch
{
Write-Host "Error logging into OneView, EXIT and Check Credentials" 
Break
}
Write-Host "Connected to OneView" -BackgroundColor DarkGreen


#Get OneView Profile, all Networks and Network Sets
Write-Host "Getting OneView Profile Details" -BackgroundColor DarkGreen
$OVProfileNetworks = Get-HPOVProfile -Name $HostName
Write-Host "Getting OneView Networks Details" -BackgroundColor DarkGreen
$OVNetworks = Get-HPOVNetwork 
Write-Host "Getting OneView NetworkSets Details" -BackgroundColor DarkGreen
$OVNetworkSets = Get-HPOVNetworkSet
$NetworkDetails=@{}

#Populate Hash Table with MAC and NAMES
 foreach ($conn in $OVProfileNetworks.Connections) 
 {
    foreach ($network in $OVNetworks) 
        {
        if ($conn.networkUri -eq $network.uri)  {$MacwithDash = $conn.mac 
        $MacwithDash = $MacwithDash -replace ":", "-"
        $NetworkDetails.Add($MacwithDash,$network.name)}

        }
         foreach ($networkset in $OVNetworkSets) 
        {
        if ($conn.networkUri -eq $networkset.uri)  {
        $MacwithDash = $conn.mac 
        $MacwithDash = $MacwithDash -replace ":", "-"
        $NetworkDetails.Add($MacwithDash,$networkset.name)}

        }
 }

 #Disconnect from OneView
 Disconnect-HPOVMgmt -Hostname "x.x.x.x"

Import-Module NetAdapter -Force


Write-Host "Renaming Network Adapters" -BackgroundColor DarkGreen
 #Rename Comptuer Adapter Names
$ServerNetworkAdapters = Invoke-Command -ComputerName $HostName {Get-NetAdapter}
 foreach ($SMacAd in $ServerNetworkAdapters)
        {
            foreach ($h in $NetworkDetails.GetEnumerator()) 
            { 
            if ($SMacAd.MacAddress -eq $h.Key)   
                { [string]$CurrentName = $SmacAD.Name
                  [string]$NewName = $h.Value
                  Invoke-Command -ComputerName $HostName -ScriptBlock {Rename-NetAdapter -Name $args[0] -NewName $args[1]} -ArgumentList $CurrentName,$NewName

                }
            
            }
        
        }



#Read CSV File and get details for each adapter
$CSVDetails =  Import-Csv .\Networking.csv | Where-Object {$_.teamname -like "*CSV*"}
$LMDetails =  Import-Csv .\Networking.csv | Where-Object {$_.teamname -like "*LM*"}
$VMDetails =  Import-Csv .\Networking.csv | Where-Object {$_.teamname -like "*VM*"}
$MGMTDetails =  Import-Csv .\Networking.csv | Where-Object {$_.teamname -like "*MGMT*"}
$ServerNetworkAdapters = Invoke-Command -ComputerName $HostName {Get-NetAdapter}


#CSV Networking
                #Get CSV Net Adapters
                $ArrayCSVTeam =@()
                foreach ($SName in $ServerNetworkAdapters) {if ($SName.Name -like "*CSV*") {$ArrayCSVTeam += $SName.Name }}
                #Create CSV Team, set IP, Remove DNS Register

                Invoke-Command -ComputerName $HostName { New-NetLbfoTeam -Name $args[0] -TeamingMode SwitchIndependent -LoadBalancingAlgorithm Dynamic -TeamMembers $args[1],$args[2] -Confirm:$false} -ArgumentList $CSVDetails.teamname,$ArrayCSVTeam[0],$ArrayCSVTeam[1]
                Invoke-Command -ComputerName $HostName {New-NetIPAddress -InterfaceAlias $args[0] -AddressFamily IPv4 -IPAddress $args[1] -PrefixLength $args[2]-Confirm:$false} -ArgumentList $CSVDetails.teamname,$CSVDetails.ipaddress,$CSVDetails.subnet
                Invoke-Command -ComputerName $HostName {Set-DnsClient -InterfaceAlias $args[0] -RegisterThisConnectionsAddress $false} -ArgumentList $CSVDetails.teamname
                Write-Host "Created CSV Team with IP" -BackgroundColor DarkGreen
            
#LM Networking         
                #Get LM Net Adapter 
                $ArrayLMTeam =@()           
                foreach ($SName in $ServerNetworkAdapters) {if ($SName.Name -like "*LM*") {$ArrayLMTeam += $SName.Name }}
                
                #Create LM Team, set IP, Remove DNS Register                
                Invoke-Command -ComputerName $HostName { New-NetLbfoTeam -Name $args[0] -TeamingMode SwitchIndependent -LoadBalancingAlgorithm Dynamic -TeamMembers $args[1],$args[2] -Confirm:$false} -ArgumentList $LMDetails.teamname,$ArrayLMTeam[0],$ArrayLMTeam[1]
                Invoke-Command -ComputerName $HostName {New-NetIPAddress -InterfaceAlias $args[0] -AddressFamily IPv4 -IPAddress $args[1] -PrefixLength $args[2] -Confirm:$false} -ArgumentList $LMDetails.teamname,$LMDetails.ipaddress,$LMDetails.subnet
                Invoke-Command -ComputerName $HostName {Set-DnsClient -InterfaceAlias $args[0] -RegisterThisConnectionsAddress $false} -ArgumentList $CSVDetails.teamname
                Write-Host "Created LM Team with IP" -BackgroundColor DarkGreen

#VM Networking         
                #Get VM Net Adapter
                $ArrayVMTeam =@() 
                foreach ($SName in $ServerNetworkAdapters) {if ($SName.Name -like "*VM*") {$ArrayVMTeam += $SName.Name }} 
                #Create LM Team
                Invoke-Command -ComputerName $HostName { New-NetLbfoTeam -Name $args[0] -TeamingMode SwitchIndependent -LoadBalancingAlgorithm HyperVPort -TeamMembers $args[1],$args[2] -Confirm:$false} -ArgumentList $VMDetails.teamname,$ArrayVMTeam[0],$ArrayVMTeam[1]
                Write-Host "Created VM Team" -BackgroundColor DarkGreen




#MGMT Networking

Write-Host "Starting Remote MGMT Team and IP Address" -BackgroundColor DarkGreen
Write-Host "Ignore Network Error from PSExec, the Scirpt is still being executed on the server" -BackgroundColor DarkGreen
Copy-Item -Path .\MGMTIPSettings.ps1 -Destination //$HostName/c$/Windows/Temp 
Copy-Item -Path .\Networking.csv -Destination //$HostName/c$/Windows/Temp 
Start-Sleep -Seconds 5
& .\psexec.exe -s /accepteula \\$HostName powershell.exe C:\Windows\Temp\MGMTIPSettings.ps1
Start-Sleep -Seconds 60

#Wait for computer to change IP and come online.
DO {Write-Host "Computer Setting IP" -BackgroundColor DarkRed
       Start-Sleep -Seconds 5}
   While (!(ComputerOnline $HostName) )
   Write-Host "MGMT IP Set" -BackgroundColor DarkGreen
   Write-Host "Computer Back Online" -BackgroundColor DarkGreen

#Set Binding order

Write-Host "Setting Binding Order" -BackgroundColor DarkGreen
Invoke-Command -ComputerName $HostName {NETSH INTERFACE IP SET INTERFACE $args[0] METRIC=1} -ArgumentList $MGMTDetails.teamname
Invoke-Command -ComputerName $HostName {NETSH INTERFACE IP SET INTERFACE $args[0] METRIC=2} -ArgumentList $VMDetails.teamname
Invoke-Command -ComputerName $HostName {NETSH INTERFACE IP SET INTERFACE $args[0] METRIC=3} -ArgumentList $LMDetails.teamname
Invoke-Command -ComputerName $HostName {NETSH INTERFACE IP SET INTERFACE $args[0] METRIC=4} -ArgumentList $CSVDetails.teamname


#Install Roles and Features
Invoke-Command -ComputerName $HostName -FilePath .\HyperV_RolesFeatures_Settings.ps1

#Restart and Wait to computer to come online
Restart-Computer -ComputerName $HostName -Force -Wait

Function CheckHyperVStatus
{

$HYPVStatus = Invoke-Command -ComputerName $HostName -ScriptBlock {Get-WindowsFeature -Name 'Hyper-V'} -ErrorAction Ignore
    

If($HYPVStatus.InstallState -eq "Installed")
    {return $true}
else
    {return $false}
}
Do {Write-Host "Waiting for Hyper-V install Status to be Installed" -BackgroundColor DarkRed 
        Start-Sleep -Seconds 30}
While(!(CheckHyperVStatus))
Write-Host "Hyper-V Role Install Complete" -BackgroundColor DarkGreen

#Disable CheckSum on Network Adapters
Invoke-Command -ComputerName $HostName -FilePath .\HyperV_Disable_CheckSum.ps1


#Create Network and SAN Switches
$VSwitchDetails =  Import-Csv .\Vswitch.csv 
$VMSANName = $VSwitchDetails.fiberswitch
$VMSwitchName = $VSwitchDetails.networkswitch 
Invoke-Command -ComputerName $HostName -FilePath .\Network_SAN_Switch.ps1 -Argumentlist $HostName, $VMSANName, $VMSwitchName, $VMDetails.teamname




#Restart and Wait to computer to come online

Restart-Computer -ComputerName $HostName -Force -Wait
Start-Sleep -Seconds 30

#Configure 
Invoke-Command -ComputerName $HostName -FilePath .\HyperV_VMQ.ps1 -ArgumentList $VMDetails.teamname

#Add 3PAR to MPIO
Invoke-Command -ComputerName $HostName -FilePath .\MPIO_3PARdataVV.ps1

#Restart and Wait to computer to come online

Restart-Computer -ComputerName $HostName -Force -Wait

   Write-Host "Computer Back Online" -BackgroundColor DarkGreen
   Write-Host "ALL TASKS COMPLETE" -BackgroundColor DarkGreen
