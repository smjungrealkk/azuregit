

    $VMtag = @{"smjung"="사용자"; "vm"="윈10"; "관리자"="realkk.store"; "avd"="Personal sessionhost"}
    # $NSGName = ""
    # $NSGRgName = ""
    $vmName = "Sessionhost"
    $privateIP = "10.224.1.10"
    $location = "koreacentral"
    $vnetName = "smjung-hostpool-vnet"
    $vnetRgName = "smjung-rg"
    $subnetName = "subnet1"
    $vmSize = "Standard_B2ms"  
    $vmRgName = "smjung-rg"  
    $nicName = $($vmName+"-nic")
    $osDiskSku = "StandardSSD_LRS"
    $osDiskName = $($vmName+"-osdisk")
    $OsDiskSize = "128"
    # $pipName = $($vmName+"-pip")
    $AdminUser = "smjung"
    $AdminPassword = "QWERasdf123!!"
    $cred = New-Object PSCredential $AdminUser, ($AdminPassword | ConvertTo-SecureString -AsPlainText -Force)

    $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRGName 
    $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName
    # $NSG = Get-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $NSGRgName    
    # $pip = New-AzPublicIpAddress -ResourceGroupName $vmRgName -Location $Location -Name $pipName -AllocationMethod Static -Sku "Standard" #-Zone $Zone                   
    $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $vmRgName -Subnet $subnet -Location $location -PrivateIpAddress $privateIP #-PublicIpAddress $pip #-EnableAcceleratedNetworking -NetworkSecurityGroup $NSG
    $VirtualMachine = New-AzVMConfig -VMName $vmName -VMSize $vmSize #-Zone $Zone #-AvailabilitySetID $AVSetID.Id
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -ComputerName $vmName -Windows -Credential $cred -TimeZone "Korea Standard Time" -EnableAutoUpdate:$false                   
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -Id "/subscriptions/2aba0708-5009-4721-88f9-22ca25e25ce6/resourceGroups/smjung-rg/providers/Microsoft.Compute/galleries/smjungcomputegallery/images/Windows-10-ent/versions/1.0.0" 
    # $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -Id "/subscriptions/2aba0708-5009-4721-88f9-22ca25e25ce6/resourceGroups/smjung-rg/providers/Microsoft.Compute/galleries/smjungcomputegallery/images/Windows-server/versions/1.0.0" 

    $VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name $OsDiskName -StorageAccountType $osDiskSku -DiskSizeInGB $OsDiskSize -CreateOption "FromImage" -Caching "ReadWrite"                                        
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $virtualMachine -Enable -ResourceGroupName $vmRgName -StorageAccountName "smjungkcaccount"

    New-AzVM -ResourceGroupName $vmRgName -Location $Location -VM $VirtualMachine -Verbose -DisableBginfoExtension -Tag $VMtag                                                                 


    $ErrorActionPreference = 'SilentlyContinue'

    # Set-AzVMExtension -ResourceGroupName $DestVMRG -Location $Location -VMName $DestVMName -Name CSE `
    # -Publisher "Microsoft.Compute" -Type "CustomScriptExtension" -TypeHandlerVersion '1.10' -Settings $winSettings -ProtectedSettings $ProtectedSettings
    
    #wait job Phase1
    Start-Sleep -Seconds 60
    
    
    #Phase 2 : AD domain Join  &  install DSC extension
    $domainpassword = 'QWERasdf123!!'
    
    $Domainjoin = @{
        Name                   = "joindomain"
        Type                   = "JsonADDomainExtension" 
        Publisher              = "Microsoft.Compute"
        typeHandlerVersion     = "1.3"
        SettingString          = "{
            ""name"": ""realkk.store"",
            ""ouPath"": """",
            ""user"": ""smjung@realkk.store"",
            ""restart"": ""true"",
            ""options"": ""3""
        }"
        ProtectedSettingString = '{
            "password":"' + $($domainpassword) + '"}'
        VMName                 = $vmName
        ResourceGroupName      = "smjung-rg"
        location               = "koreacentral"
    }
    Set-AzVMExtension @Domainjoin
    
    #wait job Phase2 joinAD
    Start-Sleep -Seconds 60
    $ErrorActionPreference = 'SilentlyContinue'
    
    $DSCinstall = @{
        Name               = "Microsoft.PowerShell.DSC"
        Type               = "DSC" 
        Publisher          = "Microsoft.Powershell"
        typeHandlerVersion = "2.73"
        SettingString      = "{
            ""modulesUrl"":""https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02482.227.zip"",
            ""ConfigurationFunction"":""Configuration.ps1\\AddSessionHost"",
            ""Properties"": {
                ""hostPoolName"": ""smjung-hostpool-personal"",
                ""registrationInfoToken"": ""eyJhbGciOiJSUzI1NiIsImtpZCI6IjQyRURFMjE4OERDMUYxMzk5QUJFNDREQTJGNzE1RDU0NDlEMjNBOUYiLCJ0eXAiOiJKV1QifQ.eyJSZWdpc3RyYXRpb25JZCI6ImY5ODE3M2FkLWU4Y2MtNGMwMi1iYTNlLTAyMzYxYmE5NTA0ZSIsIkJyb2tlclVyaSI6Imh0dHBzOi8vcmRicm9rZXItZy11cy1yMC53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1VyaSI6Imh0dHBzOi8vcmRkaWFnbm9zdGljcy1nLXVzLXIwLnd2ZC5taWNyb3NvZnQuY29tLyIsIkVuZHBvaW50UG9vbElkIjoiMjk1ODY2MTgtZGYxYy00OWM0LWI5MGYtNGVmZmZkMjM3ZTM1IiwiR2xvYmFsQnJva2VyVXJpIjoiaHR0cHM6Ly9yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJHZW9ncmFwaHkiOiJVUyIsIkdsb2JhbEJyb2tlclJlc291cmNlSWRVcmkiOiJodHRwczovLzI5NTg2NjE4LWRmMWMtNDljNC1iOTBmLTRlZmZmZDIzN2UzNS5yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJCcm9rZXJSZXNvdXJjZUlkVXJpIjoiaHR0cHM6Ly8yOTU4NjYxOC1kZjFjLTQ5YzQtYjkwZi00ZWZmZmQyMzdlMzUucmRicm9rZXItZy11cy1yMC53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1Jlc291cmNlSWRVcmkiOiJodHRwczovLzI5NTg2NjE4LWRmMWMtNDljNC1iOTBmLTRlZmZmZDIzN2UzNS5yZGRpYWdub3N0aWNzLWctdXMtcjAud3ZkLm1pY3Jvc29mdC5jb20vIiwiQUFEVGVuYW50SWQiOiI5NzlhN2RjNi0xYzVmLTQ5YmQtYTI2NS02MDlkYWY2NmUzZDIiLCJuYmYiOjE2OTg5MTM2ODgsImV4cCI6MTcwMTE4MzYwMCwiaXNzIjoiUkRJbmZyYVRva2VuTWFuYWdlciIsImF1ZCI6IlJEbWkifQ.Xr130F9OpMPXt-Ko4caFo5VVWxM0V5_XfaTo2qe8hPCUoVGCwQEu_4i-Lqn8nyUad8KqMx7vJwuWqz0q86VUe4Tk9KsjNtf1vkyk0Vcsw0-Db4QxgJr3oNBIKw6ifw3RYgQtOGiuZuRaEPkmwao2hUbi2MUgudNSQVQnlxangG0Gti-yBC614xYUVy6vN90QgB_P4VeunR_9o75NkSnqUr9zUHCs2tLEU6E_c1k7FLEZelzWD6onuUOXj1Lfx1ajEL5EcxaVx7YWx0AT5_JgQJtodtCLA7sM7ZDOEpNF0DJxy4OgE8Mb8ek_kpY6J-AYpRLtzg6sljYOIfwoCbOF4w"",
                ""aadJoin"": true
            }
        }"
        VMName                 = $vmName
        ResourceGroupName      = "smjung-rg"
        location           = "koreacentral"
    }
    Set-AzVMExtension @DSCinstall
    
    #Phase 3 : assign User
    # Get-AzVMExtension -ResourceGroupName $DestVMRG -VMName $DestVMName -Name "joindomain" 
    # $SessionHostName = $($DestVMName+".kbanknow.com")
    # Get-AzWvdSessionHost -ResourceGroupName $DestVMRG -HostPoolName $HostPoolname -Name $SessionHostName 
    # $ErrorActionPreference = "SilentlyContinue"
    # Update-AzWvdSessionHost -HostPoolName $HostPoolname -Name $SessionHostName -ResourceGroupName $DestVMRG -AssignedUser $UserUPN
    