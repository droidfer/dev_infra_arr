
# Environment Variable to be set: 
# $Env:Tenant 
# $Env:SubId 
# $Env:AppId 
# $Env:AppPass
# $Env:RGName 
# $Env:RLocation
# $Env:AppServPlan

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

New-AzResourceGroup -Name "$RGName" -Location "$RLocation"


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
# Web Application
# https://learn.microsoft.com/en-us/powershell/module/az.websites/new-azwebapp?view=azps-9.7.1

$WebAppName = "webAppArroyo"

if (! (CheckResourceExist -ResourceName $WebAppName)) {
  $Parameters = @{
    Name = $WebAppName
    ResourceGroupName = "$RGName"
    Location = "$RLocation"
    AppServicePlan = "$Env:AppServPlan"
  }

  New-AzWebApp @Parameters

} else {
  Write-Host "The WebApp Account $WebAppName already exists."
}

# FunctionApp
# https://learn.microsoft.com/en-us/powershell/module/az.functions/new-azfunctionapp?view=azps-9.7.1
# FunctionApp requires a Storage Account
$SAName = "funAppStore"
$FunApp = "funcAppArroyo"

if (! (CheckResourceExist -ResourceName $SAName)) {
  $Parameters = @{
    Name = "$SAName"
    ResourceGroupName = "$RGName"
    Location = "$RLocation" 
    SkuName = "Standard_LRS" 
    Kind = "StorageV2" 
    AccessTier = "Hot" 
    PublicNetworkAccess = "Enabled"
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

# Redis
# https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-how-to-manage-redis-cache-powershell

$RedisName = "redisArroyo"

if (! (CheckResourceExist -ResourceName $RedisName)) {
  $Parameters = @{
    Name = "$RedisName"
    ResourceGroupName = "$RGName"
    Location = "$RLocation" 
    Sku = "P1" 
    Size = "StorageV2" 
    ShardCount = 3
  }

  New-AzRedisCache @Parameters

} else {
  Write-Host "The Redis Account $RedisName already exists."
}

# Azure SQL Database
# https://learn.microsoft.com/en-us/azure/azure-sql/database/scripts/create-and-configure-database-powershell?view=azuresql

$serverName = "serverDbArr"
$sqlName = "sqlDataArr"

if (! (CheckResourceExist -ResourceName $serverName)) {
  $adminSqlLogin = "SqlAdmin"
  $password = "ChangeYourAdminPassword1"

  New-AzSqlServer -ResourceGroupName $RGNam `
  -ServerName $serverName `
  -Location $location `
  -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
} else {
  Write-Host "The SQL Server Account $serverName already exists."
}


if (! (CheckResourceExist -ResourceName $sqlName)) {
  $databaseName = "mySampleDatabase"

  $Parameters = @{
    ResourceGroupName = "$RGName"
    ServerName = "$serverName "
    DatabaseName = "$databaseName" 
    RequestedServiceObjectiveName = "S0" 
    SampleName = "AdventureWorksLT"
  }

  New-AzSqlDatabase @Parameters

} else {
  Write-Host "The SQL Database $sqlName already exists."
}

# CDN
# https://learn.microsoft.com/en-us/azure/cdn/cdn-manage-powershell

# Create a new profile
$ProfileName = "profCNDArroyo"
$EndpointName = "epCNDArroyo"

if (! (CheckResourceExist -ResourceName $sqlName)) {
  $Parameters = @{
    ProfileName = "$ProfileName"
    ResourceGroupName = "$RGName"
    Location = "$RLocation"
    Sku = "Standard_Microsoft"
  }

  New-AzCdnProfile @Parameters

} else {
  Write-Host "The CDN Profile $ProfileName already exists."
}

# Create a new endpoint
if (! (CheckResourceExist -ResourceName $EndpointName)) {
    $origin = @{
      Name = "Contoso"
      HostName = "www.contoso.com"
  };

  New-AzCdnEndpoint -ProfileName "$ProfileName" -ResourceGroupName "$RGName" -Location "$RLocation" -EndpointName "$EndpointName" -Origin $origin

} else {
  Write-Host "The CDN Endpoint $EndpointName already exists."
}

# Azure Blob Storage
# https://learn.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-powershell

$SAN2ame ="Storage2Arroyo"
$ContainerName = 'arroyyoBlobs'

if (! (CheckResourceExist -ResourceName $SAN2ame)) {
  $Parameters = @{
    Name = "$SAN2ame"
    ResourceGroupName = "$RGName"
    Location = "$RLocation" 
    SkuName = "Standard_LRS" 
  }

  New-AzStorageAccount @Parameters

} else {
  Write-Host "The Storage Account $SAN2ame already exists."
}

$StorageAccount = Get-AzStorageAccount -ResourceGroupName "$RGName" -Name "$SAN2ame"
$Context = $StorageAccount.Context

if (! (CheckResourceExist -ResourceName $ContainerName)) {
  $Parameters = @{
    Name = $ContainerName
    Context = "$Context"
    Permission = "Blob" 
  }

  New-AzStorageContainer @Parameters

} else {
  Write-Host "The Storage Container $SAN2ame already exists."
}