


    # $PublisherName = "MicrosoftWindowsDesktop"
    # $offer = "Windows-10"
    # $Skus = "20h2-ent"
    # $PublisherName = "OpenLogic"
    # $offer = "CentOS"
    # $Skus = "8_3-gen2"
    # $PublisherName = "MicrosoftWindowsServer"
    # $offer = "WindowsServer"
    # $Skus = "2019-Datacenter"
    # $Skus = "2019-Datacenter"
    $PublisherName = "MicrosoftWindowsDesktop"
    $offer = "Windows-10"
    # $Skus = "win10-21h2-pro"
    $Skus = "win10-22h2-ent"


    # $NSGName = ""
    # $NSGRgName = ""
    $VMtag = @{"smjung"="사용자"; "vm"="윈10ent"; "관리자"="realkkman"}
    $vmName = "win10ent"
    $privateIP = "10.223.1.11"
    $location = "koreacentral"
    $vnetName = "smjung-vnet"
    $vnetRgName = "smjung-rg"
    $subnetName = "subnet1"
    $vmSize = "Standard_B2ms"  
    $vmRgName = "smjung-rg"  
    $nicName = $($vmName+"-nic")
    # $osDiskSku = "Premium_LRS"
    $osDiskSku = "StandardSSD_LRS"   
    $osDiskName = $($vmName+"-osdisk")
    $OsDiskSize = "128"
    $pipName = $($vmName+"-pip")
    $AdminUser = "smjung"
    $AdminPassword = "QWERasdf123!!"
    $cred = New-Object PSCredential $AdminUser, ($AdminPassword | ConvertTo-SecureString -AsPlainText -Force)


    $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRGName 
    $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName
    # $NSG = Get-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $NSGRgName    
    $pip = New-AzPublicIpAddress -ResourceGroupName $vmRgName -Location $Location -Name $pipName -AllocationMethod Static -Sku "Standard" -Zone $Zone                   
    $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $vmRgName -Subnet $subnet -Location $location -PrivateIpAddress $privateIP -PublicIpAddress $pip #-EnableAcceleratedNetworking -NetworkSecurityGroup $NSG
    $VirtualMachine = New-AzVMConfig -VMName $vmName -VMSize $vmSize #-Zone $Zone #-AvailabilitySetID $AVSetID.Id
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -ComputerName $vmName -Windows -Credential $cred #-TimeZone "Korea Standard Time" -EnableAutoUpdate:$false                   
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $PublisherName -Offer $Offer -Skus $Skus -Version "latest"
    $VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name $OsDiskName -StorageAccountType $osDiskSku -DiskSizeInGB $OsDiskSize -CreateOption "FromImage" -Caching "ReadWrite"                                     
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id

    $VirtualMachine = Set-AzVMBootDiagnostic -VM $virtualMachine -Enable -ResourceGroupName $vmRgName -StorageAccountName "smjungkcaccount"

    New-AzVM -ResourceGroupName $vmRgName -Location $Location -VM $VirtualMachine -Verbose -DisableBginfoExtension -Tag $VMtag


    
    $VM = Get-AzVM -ResourceGroupName $vmRgName -Name $vmName
    Set-AzVMBootDiagnostic -VM $VM -Disable
    Update-AzVM -VM $VM -ResourceGroupName $vmRgName
    
