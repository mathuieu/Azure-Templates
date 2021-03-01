#######################################################
#        Déploiement d'un Template ARM local
#######################################################
#  fonction pour générer une SAS
function Get-SAS {
    param (
        OptionalParameters
    )
    $saKey = Get-AzStorageAccountKey -ResourceGroupName $ArchiveResourceGroupName -Name $ArchiveStorageAccountName
# on créé ensuite le contexte de stockage en utilisant une clé
$StorContext = New-AzStorageContext –StorageAccountName $ArchiveStorageAccountName -StorageAccountKey $saKey[0].Value 

# récupérer l'URL du ZIP dans le blob (= Générer la SAS pour l'utiliser dans le template)
$ConfigURI = New-AzStorageBlobSASToken `
  -Container 'windows-powershell-dsc' `
  -Blob $ArchiveBlobName `
  -Context $StorContext `
  -Permission r `
  -ExpiryTime (Get-Date).AddHours(2.0) -FullUri
Write-Host $ConfigURI

}
#######################################################
# connexion au compte Azure
$SubscriptionName = "Visual Studio Enterprise – MPN"
Connect-AzAccount -Subscription $SubscriptionName -UseDeviceAuthentication

# Connexion avec le certificat local sans mot de passe au tenant HSM
# Connect-ToAzureRM -TenantId "dfa0a4b1-54ec-4ed0-b3c7-c1f6d50a7b84" -ApplicationId "b4f8ea58-c965-4ae7-bf6d-a5ed348c63bb" -CertificateSubjectName CN=AutomateLogin 
# Get-AzSubscription -SubscriptionId 693c806e-0f56-4415-800a-7bb5695cea7c | Select-AzSubscription #sponsored

$ResourceGroupName = "Demo_AG_Medialog"
$location = "FranceCentral"

$TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\VM-Windows.json"
# $TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Azure\Scripts\Template\PointToSiteVPN\VPNP2S.json"
# $TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Clients\Maincare\Template ARM\template.json"
# $TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Azure\Scripts\Docker\template.json"
# $TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\new-vnet.json"
# $TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\IP.json"
# $TemplateObject = ""

$TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\VM-Windows.param.json"
# $TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\IP.param.json"
# $TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Azure\Scripts\Docker\parameters.json"
# $TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Azure\Scripts\Template\PointToSiteVPN\VPNP2S.parameters.json"

# transformation du fichier en objet non conforme
# $TemplateParameterFileText = [System.IO.File]::ReadAllText($TemplateParameterFile)
# $TemplateParameterObject = ConvertFrom-Json $TemplateParameterFileText -AsHashtable

# transformation du fichier en objet compréhensible par Azure
$azureparameters = get-content $TemplateParameterFile | convertfrom-json -ashashtable -depth 100
$TemplateParameterObject = @{ }
$azureparameters.parameters.keys | ForEach-Object { $TemplateParameterObject[$_] = $azureparameters.parameters[$_]['value'] }

# modification de l'url DSC si besoin
$TemplateParameterObject.powershellDSC_url = $ConfigURI
$TemplateParameterObject.PowershellDSC_url

# création du ressource group destination si besoin
Get-AzResourceGroup -Name $ResourceGroupName -ev notPresent -ea 0
if($notPresent){New-AzResourceGroup -Name $ResourceGroupName -Location $location}

# Test du template au format fichier
Clear-Host;Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -Verbose -TemplateParameterFile $TemplateParameterFile
# Test du template au format fichier et les parametres en objet
Clear-Host;Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -Verbose -TemplateParameterObject $TemplateParameterObject
# Get-AzLog -CorrelationId b6c4fa9f-052f-4fa2-b2a9-bb643e416b6b -DetailedOutput

# Déploiement du template
# New-AzResourceGroupDeployment -Name "Deploy-Powershell" -Mode Complete -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -Verbose -Force -TemplateParameterFile $TemplateParameterFile
New-AzResourceGroupDeployment -Name "VMDS2-Ben-2" -Mode Incremental -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile -Verbose -Force 

# Déploiement du template au format fichier et les parametres en objet
New-AzResourceGroupDeployment -Name "VMDS2-Ben-3" -Mode Incremental -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterObject $TemplateParameterObject -Verbose -Force 
