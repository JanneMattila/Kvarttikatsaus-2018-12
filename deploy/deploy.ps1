Param (
    [Parameter(HelpMessage="Deployment target resource group")] 
    [string] $ResourceGroupName = "kvarttikatsaus-local-rg",

    [Parameter(HelpMessage="Deployment target resource group location")] 
    [string] $Location = "North Europe",

    [Parameter(HelpMessage="App Service Plan's Pricing tier and instance size. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/")] 
    [ValidateSet("F1", "D1", "B1", "B2", "B3", "S1", "S2", "S3", "P1", "P2", "P3", "P1v2", "P2v2", "P3v2")]
    [string] $AppServicePricingTier = "B1",

    [Parameter(HelpMessage="App Service Plan's instance count")] 
    [ValidateRange(1, 10)]
    [int] $AppServiceInstances = 1,

    
    [Parameter(HelpMessage="Example parameter for web app application setting.")] 
    [string] $AppSettingExampleParameter = "Julkaisun oletusarvosta",

    [string] $Template = "$PSScriptRoot\azuredeploy.json",
    [string] $TemplateParameters = "$PSScriptRoot\azuredeploy.parameters.json"
)

$ErrorActionPreference = "Stop"

$date = (Get-Date).ToString("yyyy-MM-dd-HH-mm-ss")
$deploymentName = "Local-$date"

if ([string]::IsNullOrEmpty($env:RELEASE_DEFINITIONNAME))
{
    Write-Host (@"
Not executing inside Azure DevOps Release Management.
Make sure you have done "Login-AzureRmAccount" and
"Select-AzureRmSubscription -SubscriptionName name"
so that script continues to work correctly for you.
"@)
}
else
{
    $deploymentName = $env:RELEASE_RELEASENAME
}

if ((Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Warning "Resource group '$ResourceGroupName' doesn't exist and it will be created."
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Verbose
}

# Additional parameters that we pass to the template deployment
$additionalParameters = New-Object -TypeName hashtable
$additionalParameters['appServicePlanSkuName'] = $AppServicePricingTier
$additionalParameters['appServicePlanInstances'] = $AppServiceInstances

$additionalParameters['appSettingExampleParameter'] = $AppSettingExampleParameter

$result = New-AzureRmResourceGroupDeployment `
    -DeploymentName $deploymentName `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $Template `
    -TemplateParameterFile $TemplateParameters `
    @additionalParameters `
    -Mode Complete -Force `
    -Verbose

if ($result.Outputs.webAppName -eq $null -or
    $result.Outputs.webAppUri -eq $null)
{
    Throw "Template deployment didn't return web app information correctly and therefore deployment is cancelled."
}

$result

$webAppName = $result.Outputs.webAppName.value
$webAppUri = $result.Outputs.webAppUri.value

# Publish variable to the Azure DevOps agents so that they
# can be used in follow-up tasks such as application deployment
Write-Host "##vso[task.setvariable variable=Custom.WebAppName;]$webAppName"
Write-Host "##vso[task.setvariable variable=Custom.WebAppUri;]$webAppUri"
