# DevOps-Azure Powershell Deploy Infraestructure

## Features
- InfraConfig.ps1: This configures a infrastructure from zero
- InfraConfig2.ps1: Adds App Service Plan, App Service, Azure Function 

## Configuration
For the configuration, there are enviroment variables that needs to be set for the user lconnection
The environment variables are thes

`   $Env:Tenant `

`   $Env:SubId `

`   $Env:AppId `

`   $Env:AppPass `


### InfraConfig.ps1
In order to configure the structure from zero (considering the environment variable above), the script requires the configuration of the Deploy (prod, dev) , Resource Group Name and Location of the resource

Example

`   .\InfraConfig.ps1 -Deploy prod -RGName resGroup -Location  `

### InfraConfig2.ps1
In order to configure the structure requirement (considering the environment variable above), the script requires the configuration of the Deploy (prod, dev) , Resource Group Name and Location of the resource

Example

`   .\InfraConfig2.ps1 -Deploy prod -RGName resGroup -Location  `
