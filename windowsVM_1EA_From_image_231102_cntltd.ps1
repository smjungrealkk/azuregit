

# $subscriptionID = "ee8cdb3c-6dc5-4ef8-b6da-06c7567e8e0b"
# Set-AzContext -Subscription $subscriptionID


    # $PublisherName = "MicrosoftWindowsDesktop"
    # $offer = "Windows-10"
    # $Skus = "20h2-ent"
    # $PublisherName = "MicrosoftWindowsServer"
    # $offer = "WindowsServer"
    # $Skus = "2019-Datacenter"

    $VMtag = @{"smjung"="사용자"; "vm"="윈10"; "관리자"="realkkman"}
    # $NSGName = ""
    # $NSGRgName = ""
    $vmName = "win10smjung"
    $privateIP = "10.223.1.15"
    $location = "koreacentral"
    $vnetName = "smjung-vnet"
    $vnetRgName = "smjung-rg"
    $subnetName = "subnet1"
    $vmSize = "Standard_B2ms"  
    $vmRgName = "smjung-rg"  
    $nicName = $($vmName+"-nic")
    $osDiskSku = "StandardSSD_LRS"
    $osDiskName = $($vmName+"-osdisk")
    $OsDiskSize = "128"
    $pipName = $($vmName+"-pip")
    $AdminUser = "smjung"
    $AdminPassword = "QWERasdf123!!"
    $cred = New-Object PSCredential $AdminUser, ($AdminPassword | ConvertTo-SecureString -AsPlainText -Force)


    #CSE info (postscript)
    # $storageAccountName = "kcsmjungstracc"
    # $storageAccountKey = "tK2+x9uUvN6/K6eV3DP5MaHkdR0/D/Zs1T+2J1Z9Fxaf/xSBc/BRSrfLYasx9MxISS4k2+zYVWta+AStA2X7ew=="
    # $ProtectedSettings = @{"storageAccountName" = $storageAccountName; "storageAccountKey" = $storageAccountKey}
    # $winuri = "https://kcsmjungstracc.blob.core.windows.net/scripts/Postscript.ps1"
    # $winSettings = @{"fileUris" = @($winuri); "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File Postscript.ps1"}


    $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRGName 
    $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName
    # $NSG = Get-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $NSGRgName    
    $pip = New-AzPublicIpAddress -ResourceGroupName $vmRgName -Location $Location -Name $pipName -AllocationMethod Static -Sku "Standard" #-Zone $Zone                   
    $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $vmRgName -Subnet $subnet -Location $location -PrivateIpAddress $privateIP -PublicIpAddress $pip #-EnableAcceleratedNetworking -NetworkSecurityGroup $NSG
    $VirtualMachine = New-AzVMConfig -VMName $vmName -VMSize $vmSize #-Zone $Zone #-AvailabilitySetID $AVSetID.Id
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -ComputerName $vmName -Windows -Credential $cred -TimeZone "Korea Standard Time" -EnableAutoUpdate:$false                   
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -Id "/subscriptions/2aba0708-5009-4721-88f9-22ca25e25ce6/resourceGroups/smjung-rg/providers/Microsoft.Compute/galleries/smjungcomputegallery/images/Windows-10-ent/versions/1.0.0" 
    # $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -Id "/subscriptions/2aba0708-5009-4721-88f9-22ca25e25ce6/resourceGroups/smjung-rg/providers/Microsoft.Compute/galleries/smjungcomputegallery/images/Windows-server/versions/1.0.0" 

    $VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name $OsDiskName -StorageAccountType $osDiskSku -DiskSizeInGB $OsDiskSize -CreateOption "FromImage" -Caching "ReadWrite"                                     
    
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id

    $VirtualMachine = Set-AzVMBootDiagnostic -VM $virtualMachine -Enable -ResourceGroupName $vmRgName -StorageAccountName "smjungkcaccount"

    New-AzVM -ResourceGroupName $vmRgName -Location $Location -VM $VirtualMachine -Verbose -DisableBginfoExtension -Tag $VMtag                                                                 





    #Set-AzVMExtension -ResourceGroupName $vmRgName -Location $Location -VMName $vmName -Name "CSE" -Publisher "Microsoft.Compute" -Type "CustomScriptExtension" -TypeHandlerVersion "1.10" -Settings $winSettings -ProtectedSettings $ProtectedSettings