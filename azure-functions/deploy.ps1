<#
Simple deploy script for the RewritePirate Azure Function.

What it does:
- Optionally logs into Azure and sets subscription
- Creates resource group, storage account, and Function App (Linux, Python 3.11)
- Deploys the contents of this folder to the Function App (prefers `func publish`, falls back to zip deploy)
- Sets app settings: AZURE_FOUNDRY_ENDPOINT and AZURE_FOUNDRY_KEY
- Adds CORS entries for localhost and GitHub Pages origin
- Prints function URL and function key(s)

Usage examples:
.
# Interactive (prompts for missing values):
# pwsh ./deploy.ps1

# Non-interactive (pass parameters):
# pwsh ./deploy.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000" -ResourceGroup "rg-aitodo" -Location "westus2" -StorageName "aitodostorage12345" -AppName "aitodo-func-12345" -FoundryEndpoint "https://..." -FoundryKey "<key>" -GitHubPagesOrigin "https://<username>.github.io"

# Notes:
# - The script will not store secrets in plaintext in the repo. It will set the function app settings on the remote Function App.
# - You need Azure CLI and either Azure Functions Core Tools (`func`) or PowerShell's Compress-Archive + az CLI for zip deploy.
# - Run this from the `azure-functions` folder (the folder that contains host.json and your function subfolder).
#>

[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$ResourceGroup = "rg-aitodo",
    [string]$Location = "westus2",
    [string]$StorageName,
    [string]$AppName,
    [string]$FoundryEndpoint,
    [string]$FoundryKey,
    [string]$GitHubPagesOrigin = "https://<your-github-username>.github.io",
    [string[]]$AdditionalCors = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function PromptIfEmpty([string]$name, [string]$current) {
    if ([string]::IsNullOrWhiteSpace($current)) {
        return Read-Host -Prompt "Enter $name"
    }
    return $current
}

try {
    Write-Host "Running deploy script from: $(Get-Location)"

    # Ensure we're in the function folder (host.json should exist)
    if (-not (Test-Path -Path "host.json")) {
        throw "host.json not found in current directory. Run this script from the 'azure-functions' folder."
    }

    # Gather values interactively if not provided
    if (-not $SubscriptionId) {
        $SubscriptionId = Read-Host -Prompt 'Azure Subscription ID (or leave blank to use current subscription)'
    }
    if ($SubscriptionId) {
        Write-Host "Setting active subscription to $SubscriptionId"
        az account set --subscription $SubscriptionId | Out-Null
    }

    $ResourceGroup = PromptIfEmpty 'Resource Group' $ResourceGroup
    $Location = PromptIfEmpty 'Location' $Location

    if (-not $StorageName) {
        $storageCandidate = "aitodostorage$(Get-Random -Maximum 99999)"
        $StorageName = Read-Host -Prompt "Storage account name (must be globally unique, lowercase). Suggested: $storageCandidate" -Default $storageCandidate
    }
    $StorageName = $StorageName.ToLower()

    if (-not $AppName) {
        $appCandidate = "aitodo-func-$(Get-Random -Maximum 99999)"
        $AppName = Read-Host -Prompt "Function App name (must be unique). Suggested: $appCandidate" -Default $appCandidate
    }

    if (-not $FoundryEndpoint) {
        $FoundryEndpoint = Read-Host -Prompt 'Azure Foundry / OpenAI endpoint (leave blank to set later on the portal)'
    }
    if (-not $FoundryKey) {
        $FoundryKey = Read-Host -Prompt 'Azure Foundry / OpenAI API key (leave blank to set later in portal or via CLI)'
    }

    # Create resource group
    Write-Host "Creating resource group $ResourceGroup in $Location (idempotent)"
    az group create --name $ResourceGroup --location $Location | Out-Null

    # Create storage account (idempotent)
    Write-Host "Creating storage account $StorageName"
    az storage account create --name $StorageName --resource-group $ResourceGroup --location $Location --sku Standard_LRS | Out-Null

    # Create Function App (Linux, Python 3.11)
    Write-Host "Creating Function App $AppName"
    az functionapp create --resource-group $ResourceGroup --consumption-plan-location $Location --name $AppName --storage-account $StorageName --runtime python --runtime-version 3.11 --functions-version 4 --os-type Linux | Out-Null

    # Deploy code: prefer 'func publish' if available
    $funcCmd = Get-Command func -ErrorAction SilentlyContinue
    if ($funcCmd) {
        Write-Host "Found Azure Functions Core Tools (func). Publishing app..."
        func azure functionapp publish $AppName --python
    }
    else {
        Write-Host "Azure Functions Core Tools (func) not found. Falling back to zip deploy. Creating package..."
        $tmpZip = Join-Path -Path $env:TEMP -ChildPath ("functiondeploy_$([guid]::NewGuid().ToString()).zip")
        if (Test-Path $tmpZip) { Remove-Item $tmpZip -Force }
        Compress-Archive -Path * -DestinationPath $tmpZip -Force
        Write-Host "Uploading zip to $AppName..."
        az functionapp deployment source config-zip --resource-group $ResourceGroup --name $AppName --src $tmpZip | Out-Null
        Remove-Item $tmpZip -Force
    }

    # Set app settings for Foundry/OpenAI if provided
    $appSettings = @{}
    if ($FoundryEndpoint) { $appSettings.Add('AZURE_FOUNDRY_ENDPOINT',$FoundryEndpoint) }
    if ($FoundryKey) { $appSettings.Add('AZURE_FOUNDRY_KEY',$FoundryKey) }
    if ($appSettings.Keys.Count -gt 0) {
        Write-Host "Setting app settings on $AppName"
        $settingsArray = @()
        foreach ($k in $appSettings.Keys) { $settingsArray += "$k=$($appSettings[$k])" }
        az functionapp config appsettings set --name $AppName --resource-group $ResourceGroup --settings $settingsArray | Out-Null
    }

    # Configure CORS: include GitHub Pages origin (user-provided) and localhost dev origin
    $corsOrigins = @($GitHubPagesOrigin, 'http://localhost:5173') + $AdditionalCors
    Write-Host "Adding CORS origins: $($corsOrigins -join ', ')"
    foreach ($origin in $corsOrigins) {
        if (-not [string]::IsNullOrWhiteSpace($origin)) {
            az functionapp cors add --name $AppName --resource-group $ResourceGroup --allowed-origins $origin | Out-Null
        }
    }

    # Retrieve function keys (if function exists and keys are available)
    Write-Host "Retrieving function and host keys (if available)"
    try {
        $funcKeys = az functionapp function keys list --resource-group $ResourceGroup --name $AppName --function-name RewritePirate --output json | ConvertFrom-Json
    } catch {
        $funcKeys = $null
    }

    $hostKeys = az functionapp keys list --resource-group $ResourceGroup --name $AppName --output json | ConvertFrom-Json

    $baseUrl = "https://$AppName.azurewebsites.net/api/RewritePirate"
    Write-Host "\nDeployment complete. Function base URL: $baseUrl"
    if ($funcKeys) {
        Write-Host "Function-specific keys:"
        $funcKeys.PSObject.Properties | ForEach-Object { Write-Host " - $($_.Name): $($_.Value)" }
    } else {
        Write-Host "(No function-specific keys found yet or function not available to list keys.)"
    }
    if ($hostKeys) {
        Write-Host "Host keys:"
        $hostKeys.PSObject.Properties | ForEach-Object { Write-Host " - $($_.Name): $($_.Value)" }
    }

    Write-Host "Example curl (no auth):\n  curl -X POST $baseUrl -H 'Content-Type: application/json' -d '{\"task\":\"Test task\",\"model\":\"gpt-5-nano\"}'"
    if ($funcKeys -and $funcKeys.default) {
        Write-Host "Example curl (with function key):\n  curl -X POST \"$baseUrl?code=$($funcKeys.default)\" -H 'Content-Type: application/json' -d '{\"task\":\"Test task\",\"model\":\"gpt-5-nano\"}'"
    }

    Write-Host "\nIf you deployed your GH Pages site, update VITE_AZURE_FUNCTION_URL to: $baseUrl (or append ?code=<key> if authLevel=function) before building the site for production."

} catch {
    Write-Error "Deployment failed: $_"
    exit 1
}
