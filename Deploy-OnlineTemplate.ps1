#######################################################
#        Déploiement d'un Template ARM Online
#     login and subscribtion select before 
#######################################################

$ResourceGroupName = "SponsorFrance"
$location = "francecentral"

# $TemplateFile =         "https://github.com/mathuieu/Azure-Templates/raw/master/Cascade/new-vnet.json"
$TemplateFile =         "https://github.com/mathuieu/Azure-Templates/raw/master/Cascade/VM-Windows.json"
$TemplateParameterFile ="https://github.com/mathuieu/Azure-Templates/raw/master/Cascade/VM-Windows.param.json"

# création du ressource group destination si besoin
Get-AzureRmResourceGroup -Name $ResourceGroupName -ev notPresent -ea 0
if($notPresent){New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location}

Clear-Host;Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $TemplateFile -Verbose -TemplateParameterUri $TemplateParameterFile
# Get-AzureRMLog -CorrelationId 15e7282b-5f90-4b02-b45b-c94665f5d885 -DetailedOutput

New-AzureRmResourceGroupDeployment -Name "Deploy-Powershell" -Mode Incremental -ResourceGroupName $ResourceGroupName -TemplateUri $TemplateFile -Verbose -Force -TemplateParameterUri $TemplateParameterFile
