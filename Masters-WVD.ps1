exit
<#
.SYNOPSIS
    Gestion des images de master WVD
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    last maj : 26/02/2021 à 09:33:32 
    last use : 
    https://docs.microsoft.com/fr-fr/azure/virtual-machines/windows/capture-image-resource
#>
$tenantID = "8de15a81-f1b0-42ee-86ae-ca75c1b8ba65" # IFPEN.fr
$SubscriptionName = "IFP-School"

Connect-AzAccount -Subscription $SubscriptionName -UseDeviceAuthentication -Tenant $tenantID

$ResourceGroupName = "rg-img-we-vdischool"
$location = "westeurope"

# Réseau
# $VnetResourceGroupName = "rg-hub-we-vdischool"
$VnetResourceGroupName = $ResourceGroupName
$VirtualNetworkName = "vn-img-we-vdischool"
$SubnetName = "sn-vdischool-img"
$usePublicIP = $true

# Nom et taille
$VMName = "Master-IFPEN"
$DNSLabel = "$($vmname.tolower())-$(Get-Random -Minimum 1000 -Maximum 9999)" # si IP publique
$VMsize = "Standard_D4_v4"#"Standard_B4ms"#"Standard_B2s"#"Standard_A2"

$OSdiskName = "$VMName-OSdisk"
$DiskStorageType = "Standard_LRS"


# Get-AzVMImagePublisher -Location $location
$publisher = "MicrosoftWindowsDesktop"
# Get-AzVMImageOffer -Location $location -PublisherName $publisher
$offer = "windows-10"
# Get-AzVMImageSku -Location $location -PublisherName $publisher -Offer $offer | ft -autosize Skus, Offer, PublisherName, Location
$Sku = "20h2-evd" # W10 multisession

$LocalAdmin = "AdminLocal"
$LocalPass = "PasswordLocal*"

# création du ressource group destination si besoin
Get-AzResourceGroup -Name $ResourceGroupName -ev notPresent -ea 0
if($notPresent){New-AzResourceGroup -Name $ResourceGroupName -Location $location #-Tag @{'Admin name'='Mathieu Quienne'}}


################################
#region création du Vnet si besoin
$VirtualNetwork = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $VnetResourceGroupName -ev notPresent -ea 0
if($notPresent){
    # Create the subnets.
    $Subnet1 = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix 10.86.0.0/24
    
    Write-Host "création du vNet $VirtualNetworkName..."
    # Create a virtual network.
    $VirtualNetwork=New-AzVirtualNetwork `
    -ResourceGroupName $VnetResourceGroupName `
    -Location $location `
    -Name $VirtualNetworkName `
    -AddressPrefix 10.86.0.0/16 `
    -Subnet $Subnet1
}
#endregion
################################

################################
#region local credentials + NIC
$SecurePassword = ConvertTo-SecureString $LocalPass -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($LocalAdmin, $SecurePassword);
$SubnetID = ($VirtualNetwork.Subnets | Where-Object{$_.name -eq $SubnetName}).id

$NicName = "$VMName-NIC"
if($usePublicIP){# Avec IP publique :
    $IPName = "$VMName-IP"
    $PublicIp = New-AzPublicIpAddress -Name $IPName -ResourceGroupName $ResourceGroupName -Location $location -AllocationMethod Dynamic -DomainNameLabel $DNSLabel
    $NIC = Get-AzNetworkInterface -Name $NicName -ResourceGroupName $ResourceGroupName -ev NICnotPresent -ea 0
    if($NICnotPresent){
        $NIC = New-AzNetworkInterface -Name $NicName -ResourceGroupName $ResourceGroupName -Location $location -SubnetId $SubnetID -PublicIpAddressId $PublicIp.Id
    }
    else
    {
        Write-Host "La carte réseau $NicName existe déja, on la réutilise" -foregroundcolor Cyan
    }
}
else {# Sans IP Publique :
    $NIC = Get-AzNetworkInterface -Name $NicName -ResourceGroupName $ResourceGroupName -ev NICnotPresent -ea 0
    if($NICnotPresent){
        $NIC = New-AzNetworkInterface -Name $NicName -ResourceGroupName $ResourceGroupName -Location $location -SubnetId $SubnetID
    }
    else
    {
        Write-Host "La carte réseau $NicName existe déja, on la réutilise" -foregroundcolor Cyan
    }
}
#endregion
################################

################################
#region Paramétrage de la machine viruelle (Config + r?seau + stockage des disques + diagnostic)
$myVm = New-AzVMConfig -VMName $VMName -VMSize $VMsize
$myVM = Add-AzVMNetworkInterface -VM $myVm -Id $NIC.Id

if($newDisk){
    $myVM = Set-AzVMOperatingSystem -VM $myVM -Windows -ComputerName $VMName -ProvisionVMAgent -EnableAutoUpdate -Credential $Credential
    $myVM = Set-AzVMSourceImage -VM $myVM -PublisherName $publisher -Offer $offer -Skus $Sku -Version "latest"
}

if($managedDisk){ # pour les disques managés
    if($newDisk){
        # avec new managed disk:
        Write-Host "création d'un nouveau disque managé..." -ForegroundColor Cyan
        $myVM = Set-AzVMOSDisk -VM $myVM -Name $OSdiskName -StorageAccountType $DiskStorageType -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite -Windows
    }
    else {
        # avec existing managed disk:
        Write-Host "Utilisation d'un disque managé existant : $OSdiskName" -ForegroundColor Cyan
        $OSdisk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $OSdiskName
        $myVM = Set-AzVMOSDisk -VM $myVM -ManagedDiskId $OSdisk.Id -StorageAccountType $DiskStorageType -DiskSizeInGB 128 -CreateOption Attach -Windows
        # $myVm.OSProfile = $null
    }
}
#endregion
###############################

# création de la machine
write-host "création de la machine $VMName..." -f Cyan
New-AzVM -ResourceGroupName $ResourceGroupName -Location $location -VM $myVM -ErrorVariable creationerror

###################################
#region Vérifications post-install
if(-not($creationerror)){
    Write-Host "La machine a été créée avec succès !" -f Green
    Write-Host "Vérifications :" -f Cyan
    $vmOK = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName
    $vmOK.Name
    $nic.IpConfigurations.PrivateIpAddress
    if($usePublicIP){$(get-AzPublicIpAddress -Name $($nic.IpConfigurations.PublicIpAddress.Id.Split('/'))[-1] -ResourceGroupName $ResourceGroupName).ipaddress}
}
#endregion

#########################################
#region [3] Snapshot du disque de la VM Avant le sysprep
# $arrêt de la machine
$vm = get-AzVm -ResourceGroupName $resourceGroupName -Name $vmName
$vm | Stop-AzVM  -Force
Stop-AzVM -VMName $vmName -ResourceGroupName $resourceGroupName -Force

$snapshotName = "Snapshot-$VMName-$($(New-Guid).guid.Split('-')[0])"
$vmOSDisk = $vm.StorageProfile.OsDisk.Name
$Disk = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $vmOSDisk
$SnapshotConfig = New-AzSnapshotConfig -SourceUri $Disk.Id -CreateOption Copy -Location $Location 

$Snapshot=New-AzSnapshot -Snapshot $snapshotConfig -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName

$vm | Start-AzVM
$vm | Start-AzVM
#endregion


#########################################
#region [4] Snapshot du disque de la VM Après le sysprep + ajout à l'image Gallery

# https://docs.microsoft.com/fr-fr/azure/virtual-machines/shared-images-powershell
# https://docs.microsoft.com/fr-fr/azure/virtual-machines/image-version-snapshot-powershell

$ImageName = "Image-$VMName-Sysprep-$($(New-Guid).guid.Split('-')[0])"

Set-AzVm -ResourceGroupName $resourceGroupName -Name $vmName -Generalized
$vm = Get-AzVM -Name $vmName -ResourceGroupName $rgName
$image = New-AzImageConfig -Location $location -SourceVirtualMachineId $vm.Id
New-AzImage -Image $image -ImageName $imageName -ResourceGroupName $rgName