# Environment Variable to be set: 
# $Env:Tenant 
# $Env:SubId 
# $Env:AppId 
# $Env:AppPass
# $Env:RGName 
# $Env:RLocation
# $Env:Deploy

#####################################
# Connect using an App Registration #
#####################################
# The configuration are performed through enviroment variables

$TenantId = $Env:Tenant
$SubscriptionId = $Env:SubId
$ApplicationId = $Env:AppId
$ApplicationPassword = $Env:AppPass

$ApplicationSecuredPassword = ConvertTo-SecureString -String $ApplicationPassword -AsPlainText

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $ApplicationSecuredPassword
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Subscription $subscriptionId -Credential $Credential


#########################
# Create Resource Group #
#########################
# ARM Template: https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/resourcegroups?pivots=deployment-language-arm-template
# Command: https://learn.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroup

$RGName = $Env:RGName
$RLocation = $Env:RLocation

Get-AzureRmResourceGroup -Name $RGName -ErrorVariable notPresent -ErrorAction SilentlyContinue

if (!($notPresent))
{
  New-AzResourceGroup -Name "$RGName" -Location "$RLocation"
}

##############################
# Create PowerShell Function #
##############################

# function CheckResourceExist ([string] $ResourceName, [string]$ResourceGroup = "") {
function CheckResourceExist {
  param (
    [Parameter(Mandatory)]
    [string]$ResourceName
  )

  $Parameters = @{
    Name = "$ResourceName"
    ErrorAction = "SilentlyContinue"
  }

  if ($RGName) {
    $Parameters += @{
      ResourceGroupName = $RGName
    }
  }

  $Exist = Get-AzResource @Parameters

  return $Exist ? $true : $false
}


##############################
# Architecture Configuration #
##############################
# App Service Plan
# https://learn.microsoft.com/en-us/powershell/module/az.websites/new-azappserviceplan?view=azps-9.7.1

$AppServ = "appServArroyo_dev"
if( $Env:Deploy == "Prod" ){
  $AppServ = "appServArroyo_prod"
}

if (! (CheckResourceExist -ResourceName $AppServ)) {
  $Parameters = @{
    Name = $AppServ
    ResourceGroupName = "$RGName"
    Location = "$RLocation"
    Tier = "Basic" 
    NumberofWorkers = 2 
    WorkerSize = "Small"
  }

  New-AzAppServicePlan @Parameters

} else {
  Write-Host "The Service Plan Account $AppServ already exists."
}


# Web Application
# https://learn.microsoft.com/en-us/powershell/module/az.websites/new-azwebapp?view=azps-9.7.1
$WebAppName = "webAppArroyo_dev"
if( $Env:Deploy == "Prod" ){
  $WebAppName = "webAppArroyo_prod"
}

if (! (CheckResourceExist -ResourceName $WebAppName)) {
  $Parameters = @{
    Name = $WebAppName
    ResourceGroupName = "$RGName"
    Location = "$RLocation"
    AppServicePlan = "$AppServ"
  }

  New-AzWebApp @Parameters

} else {
  Write-Host "The WebApp Account $WebAppName already exists."
}


# FunctionApp
# https://learn.microsoft.com/en-us/powershell/module/az.functions/new-azfunctionapp?view=azps-9.7.1
# FunctionApp requires a Storage Account
$SAName = "funAppStore_dev"
$FunApp = "funcAppArroyo_dev"
if( $Env:Deploy == "Prod" ){
  $SAName = "funAppStore_prod"
  $FunApp = "funcAppArroyo_prod"
}

if (! (CheckResourceExist -ResourceName $SAName)) {
  $Parameters = @{
    Name = "$SAName"
    ResourceGroupName = "$RGName"
    Location = "$RLocation" 
    Kind = "StorageV2" 
    PublicNetworkAccess = "Enabled"
  }

  if( $Env:Deploy == "Prod" ){
    $Parameters.SkuName = "Premium_LRS"
    $Parameters.AccessTier = "Hot"
  }else{
    $Parameters.SkuName = "Standard_LRS"
    $Parameters.AccessTier = "Cool"
  }

  New-AzStorageAccount @Parameters

} else {
  Write-Host "The Storage Account $SAName already exists."
}

if (! (CheckResourceExist -ResourceName $FunApp)) {
  $Parameters = @{
    Name = "$FunApp"
    ResourceGroupName = "$RGName"
    Location = "$RLocation" 
    StorageAccountName = "$SAName" 
    Runtime = "PowerShell" 
  }

  New-AzFunctionApp @Parameters

} else {
  Write-Host "The Function App $FunApp already exists."
}