#######################################################
#        Déploiement d'un Template ARM
#######################################################
# connexion au compte Azure
#Login-AzureRmAccount –SubscriptionName “Bordeaux - IMS" -Credential $(Get-Credential -UserName "mathieu.quienne@infeeny.com" -Message "Identifiants pour Azure")

$ResourceGroupName = "cascadejson"
$location = "West Europe"
# $TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Clients\Maincare\Template ARM\template.json"

# $TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Azure\Scripts\Docker\template.json"
# $TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Infeeny\Azure\Scripts\Docker\parameters.json"

$TemplateFile = "$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\vnet.json"
$TemplateParameterFile ="$env:HOMEDRIVE$env:HOMEPATH\GitHub\Azure-Templates\Cascade\vnet.param.json"

# création du ressource group destination si besoin
Get-AzureRmResourceGroup -Name $ResourceGroupName -ev notPresent -ea 0
if($notPresent){New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location}

# Clear-Host;Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -Verbose -TemplateParameterFile $TemplateParameterFile
#Get-AzureRMLog -CorrelationId 15e7282b-5f90-4b02-b45b-c94665f5d885 -DetailedOutput

New-AzureRmResourceGroupDeployment -Name "Deploy-Powershell" -Mode Complete -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -Verbose -Force -TemplateParameterFile $TemplateParameterFile
