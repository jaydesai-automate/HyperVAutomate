
#Script disables Checksum for all Physical Nics#
Set-ExecutionPolicy Unrestricted

Write-Host  "Now the script will disable Checksum" -BackgroundColor DarkGreen

Get-NetAdapter -Physical | ?{$_.Status -eq "up"} | Get-NetAdapterAdvancedProperty -RegistryKeyword *checksum* | Set-NetAdapterAdvancedProperty -DisplayValue disabled -NoRestart

Write-Host  "All CheckSum have been disabled" -BackgroundColor DarkGreen
