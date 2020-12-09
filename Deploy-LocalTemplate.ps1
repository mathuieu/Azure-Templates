#######################################################
#        Déploiement d'un Template ARM local
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
$TemplateObject = ""

$TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\VM-Windows.param.json"
# $TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\IP.param.json"
# $TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Azure\Scripts\Docker\parameters.json"
# $TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Azure\Scripts\Template\PointToSiteVPN\VPNP2S.parameters.json"

$TemplateParameterFileText = [System.IO.File]::ReadAllText($TemplateParameterFile)
$TemplateParameterObject = ConvertFrom-Json $TemplateParameterFileText -AsHashtable

# modification de l'url DSC si besoin
$NEW_PowershellDSC_url = $ConfigURI
$TemplateParameterObject.parameters.PowershellDSC_url.value = $NEW_PowershellDSC_url
$TemplateParameterObject.parameters.PowershellDSC_url

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
New-AzResourceGroupDeployment -Name "VMDSC9-Final" -Mode Incremental -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile -Verbose -Force 
