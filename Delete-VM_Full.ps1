<#
.SYNOPSIS
    Supprime une VM Azure avec tous ses composants
.DESCRIPTION
    Supprimme la VM, la carte réseau, l'IP publique si besoin et le disque
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    composants à supprimer
.OUTPUTS
    résultat
.NOTES
    # création 04/01/2019 Mathieu Quienne
    # dernière modification 14/12/2020 à 16:12 
    # dernière utilisation 14/12/2020 à 16:14
    réencodage en UTF-8 pour Powershell 7.1 
#>
param(
    # Nom
    [string]$VMName, 
    [string]$ResourceGroupName,

    [string]$SubscriptionName = "Visual Studio Enterprise - MPN",
    $autoConnexion = $false,
    $Connexion = $false
    
)
# [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# $OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
# $OutputEncoding = New-Object -typename System.Text.UTF8Encoding
# [Console]::OutputEncoding = New-Object -typename System.Text.UTF8Encoding
# [System.Console]::OutputEncoding
#################################################
#region login
if($autoConnexion){
    Connect-ToAzureRM -TenantId "dfa0a4b1-54ec-4ed0-b3c7-c1f6d50a7b84" -ApplicationId "b4f8ea58-c965-4ae7-bf6d-a5ed348c63bb" -CertificateSubjectName CN=AutomateLogin
    Select-AzSubscription –SubscriptionName "Pass Azure Gmail" 
}
elseif($Connexion){
    Connect-AzAccount -Subscription $SubscriptionName -UseDeviceAuthentication
}
#endregion login

#region analyse de la VM
try{
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -VMName $vmName -ErrorVariable VMnotExist -ea 0
    if($vmnotExist){throw "La VM $VMname est introuvable"}
    Write-Host "VM $VMName trouvée !" -f Green
 
    Write-Host "Cartes réseaux :" -f Cyan
    foreach($nicID in $vm.NetworkProfile.NetworkInterfaces.id){
        $($nicID.Split('/'))[-1]
        $NIC = Get-AzNetworkInterface -Name $nicID.split('/')[-1] -ResourceGroupName $ResourceGroupName
    }

    Write-Host "Disque OS :" -f Cyan
    $vm.StorageProfile.OsDisk.Name
    
    # data disk
    
    # PIP
    if($null -ne $nic.IpConfigurations.PublicIpAddress){
        Write-Host "Public IP :" -f Cyan
        $PIPName = $($nic.IpConfigurations.PublicIpAddress.Id.Split('/'))[-1]
        $PIP = Get-AzPublicIpAddress -Name $PIPName -ResourceGroupName $ResourceGroupName
        Write-Host "$PIPName ($($PIP.ipaddress))"
    }

    Write-Host "Voulez-vous continuer et supprimer La VM " -NoNewline -f Yellow
    Write-Host "$VMName" -f Magenta -NoNewline
    Write-Host " ?" -f Yellow
    $r = read-host "O/[N]"
    if($r -ne "o"){throw "Supression anulée"}
    
    $vmStatus = Get-AzVM -ResourceGroupName $ResourceGroupName -VMName $vmName -ErrorAction Stop -Status
    $status = $vmStatus.statuses.displaystatus[1]
    switch ($status) {
        "VM Running" { 
            Write-Host "La VM est démarrée, on l'arrête..." -f Cyan
            Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force -ea stop
        }
        "VM deallocated"{
            Write-Host "La VM est éteinte et déprovisionnée" -f Cyan
        }
        "VM stopped"{
            Write-Host "La VM est éteinte, on la déprovisionne..." -f Cyan
            Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force -ea stop
            Write-Host "La VM a bien été déprovisionnée" -f Green
        } 
        Default {throw "La VM est dans un Statut inconnu : $status"}
    }

    Write-Host -f Cyan "`nSuppression de la VM..."
    Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force

    Write-Host -f Cyan "Suppression du disques OS..."
    Remove-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $vm.StorageProfile.OsDisk.Name -Force

    Write-Host -f Cyan "Suppression des cartes réseaux..."
    foreach($nicID in $vm.NetworkProfile.NetworkInterfaces.id){
        $nicID.split('/')[-1]
        Remove-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Name $nicID.split('/')[-1] -Force
    }    
    
    if($null -ne $nic.IpConfigurations.PublicIpAddress){
        Write-Host -f Cyan "Suppression de l'IP Publique..."
        Remove-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $PIPName -Force
    }
    Write-Host -f Green "Suppression OK"
}
catch {
    Write-Host -f Red $_.Exception.Message
}
