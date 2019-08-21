#######################################################
#        Déploiement d'un Template ARM
#######################################################
# connexion au compte Azure
# Login-AzureRmAccount –SubscriptionName “Bordeaux - IMS" -Credential $(Get-Credential -UserName "mathieu.quienne@infeeny.com" -Message "Identifiants pour Azure")
# Connexion avec le certificat local sans mot de passe au tenant HSM
Connect-ToAzureRM -TenantId "dfa0a4b1-54ec-4ed0-b3c7-c1f6d50a7b84" -ApplicationId "b4f8ea58-c965-4ae7-bf6d-a5ed348c63bb" -CertificateSubjectName CN=AutomateLogin 
Get-AzureRmSubscription -SubscriptionId 693c806e-0f56-4415-800a-7bb5695cea7c | Select-AzureRmSubscription #sponsored

$ResourceGroupName = "IVANTI"
$location = "FranceCentral"

# $TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Azure\Scripts\Template\PointToSiteVPN\VPNP2S.json"
# $TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Clients\Maincare\Template ARM\template.json"
# $TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Azure\Scripts\Docker\template.json"
$TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\VM-Windows.json"
# $TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\new-vnet.json"
# $TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\IP.json"

# $TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\IP.param.json"
$TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\VM-Windows.param.json"
# $TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Azure\Scripts\Docker\parameters.json"
# $TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Azure\Scripts\Template\PointToSiteVPN\VPNP2S.parameters.json"

# création du ressource group destination si besoin
Get-AzureRmResourceGroup -Name $ResourceGroupName -ev notPresent -ea 0
if($notPresent){New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location}

Clear-Host;Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -Verbose -TemplateParameterFile $TemplateParameterFile
# Get-AzureRMLog -CorrelationId b6c4fa9f-052f-4fa2-b2a9-bb643e416b6b -DetailedOutput

# New-AzureRmResourceGroupDeployment -Name "Deploy-Powershell" -Mode Complete -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -Verbose -Force -TemplateParameterFile $TemplateParameterFile
New-AzureRmResourceGroupDeployment -Name "DCIvanti" -Mode Incremental -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParameterFile -Verbose -Force
