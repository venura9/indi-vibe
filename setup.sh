#!/bin/bash
# =============================================================================
# Azure Indie Artist Platform — Resource Setup Script
# Run this in Azure Cloud Shell (bash)
# https://shell.azure.com
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
#
# What it does:
#   1. Creates all Azure resources for Phase 2a and 2b
#   2. Captures all values needed for GitHub Actions secrets
#   3. Prints a summary at the end — copy/paste into GitHub
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# CONFIG — change these if needed
# -----------------------------------------------------------------------------
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP="rg-indie-artist-platform"
LOCATION="australiaeast"
SWA_LOCATION="eastasia"           # SWA Free tier not available in australiaeast

FUNCTIONAPP_NAME="func-indie-artist-platform"
FUNCTIONAPP_PLAN="plan-indie-artist-platform"
STORAGE_ACCOUNT="stindieartistpltfrm"  # max 24 chars, lowercase, no hyphens
SWA_NAME="swa-indie-artist-platform"
COSMOS_ACCOUNT="cosmos-indie-artist-platform"
COSMOS_DB="indie-artist-db"
COSMOS_CONTAINER="smartlinks"
SP_NAME="sp-indie-artist-platform"
GITHUB_REPO="venura9/indie-artist-platform"  # update with actual repo name

echo ""
echo "============================================="
echo " Azure Indie Artist Platform — Setup Script"
echo "============================================="
echo ""
echo "Subscription : $SUBSCRIPTION_ID"
echo "Resource group: $RESOURCE_GROUP"
echo "Location      : $LOCATION"
echo ""

# -----------------------------------------------------------------------------
# RESOURCE GROUP
# -----------------------------------------------------------------------------
echo ">>> Creating resource group..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none
echo "    Done."

# -----------------------------------------------------------------------------
# STORAGE ACCOUNT (required by Function App)
# -----------------------------------------------------------------------------
echo ">>> Creating storage account..."
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --output none
echo "    Done."

# -----------------------------------------------------------------------------
# FUNCTION APP
# -----------------------------------------------------------------------------
echo ">>> Creating Function App (Consumption, Python 3.11)..."
az functionapp create \
  --name "$FUNCTIONAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --consumption-plan-location "$LOCATION" \
  --storage-account "$STORAGE_ACCOUNT" \
  --runtime python \
  --runtime-version 3.11 \
  --os-type linux \
  --functions-version 4 \
  --output none
echo "    Done."

# -----------------------------------------------------------------------------
# STATIC WEB APP
# -----------------------------------------------------------------------------
echo ">>> Creating Static Web App (Free tier)..."
az staticwebapp create \
  --name "$SWA_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$SWA_LOCATION" \
  --sku Free \
  --output none
echo "    Done."

# -----------------------------------------------------------------------------
# LINK FUNCTION APP TO STATIC WEB APP
# -----------------------------------------------------------------------------
echo ">>> Linking Function App to Static Web App..."
FUNCTIONAPP_ID=$(az functionapp show \
  --name "$FUNCTIONAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query id -o tsv)

az staticwebapp backends link \
  --name "$SWA_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --backend-resource-id "$FUNCTIONAPP_ID" \
  --backend-region "$LOCATION" \
  --output none
echo "    Done."

# -----------------------------------------------------------------------------
# COSMOS DB (serverless)
# -----------------------------------------------------------------------------
echo ">>> Creating Cosmos DB account (serverless)..."
echo "    Note: Free Tier limited to one account per subscription."
echo "    If this fails, re-run without --enable-free-tier true"

az cosmosdb create \
  --name "$COSMOS_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --locations regionName="$LOCATION" \
  --capabilities EnableServerless \
  --enable-free-tier true \
  --output none
echo "    Done."

echo ">>> Creating Cosmos DB database..."
az cosmosdb sql database create \
  --account-name "$COSMOS_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$COSMOS_DB" \
  --output none
echo "    Done."

echo ">>> Creating Cosmos DB container..."
az cosmosdb sql container create \
  --account-name "$COSMOS_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --database-name "$COSMOS_DB" \
  --name "$COSMOS_CONTAINER" \
  --partition-key-path "/id" \
  --output none
echo "    Done."

# -----------------------------------------------------------------------------
# SERVICE PRINCIPAL FOR GITHUB ACTIONS
# -----------------------------------------------------------------------------
echo ">>> Creating service principal for GitHub Actions..."
AZURE_CREDENTIALS=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --sdk-auth \
  --output json)
echo "    Done."

# -----------------------------------------------------------------------------
# CAPTURE ALL SECRET VALUES
# -----------------------------------------------------------------------------
echo ""
echo ">>> Capturing secret values..."

SWA_DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
  --name "$SWA_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "properties.apiKey" -o tsv)

FUNCTIONAPP_PUBLISH_PROFILE=$(az functionapp deployment list-publishing-profiles \
  --name "$FUNCTIONAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --xml)

COSMOS_ENDPOINT=$(az cosmosdb show \
  --name "$COSMOS_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query documentEndpoint -o tsv)

COSMOS_KEY=$(az cosmosdb keys list \
  --name "$COSMOS_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query primaryMasterKey -o tsv)

SWA_HOSTNAME=$(az staticwebapp show \
  --name "$SWA_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "defaultHostname" -o tsv)

echo "    Done."

# -----------------------------------------------------------------------------
# SAVE TO FILE
# -----------------------------------------------------------------------------
OUTPUT_FILE="github-secrets.txt"

cat > "$OUTPUT_FILE" <<EOF
=============================================================================
 GitHub Actions Secrets
 Generated: $(date)
 Repo: $GITHUB_REPO
=============================================================================

Copy each value below into:
GitHub → repo → Settings → Secrets and variables → Actions → New repository secret

-----------------------------------------------------------------------------
AZURE_CREDENTIALS
-----------------------------------------------------------------------------
$AZURE_CREDENTIALS

-----------------------------------------------------------------------------
AZURE_STATIC_WEB_APPS_API_TOKEN
-----------------------------------------------------------------------------
$SWA_DEPLOYMENT_TOKEN

-----------------------------------------------------------------------------
AZURE_FUNCTIONAPP_PUBLISH_PROFILE
-----------------------------------------------------------------------------
$FUNCTIONAPP_PUBLISH_PROFILE

-----------------------------------------------------------------------------
COSMOS_ENDPOINT
-----------------------------------------------------------------------------
$COSMOS_ENDPOINT

-----------------------------------------------------------------------------
COSMOS_KEY
-----------------------------------------------------------------------------
$COSMOS_KEY

-----------------------------------------------------------------------------
COSMOS_DB
-----------------------------------------------------------------------------
$COSMOS_DB

-----------------------------------------------------------------------------
COSMOS_CONTAINER
-----------------------------------------------------------------------------
$COSMOS_CONTAINER

=============================================================================
 Reference Info (not secrets)
=============================================================================

SWA default hostname : $SWA_HOSTNAME
Function App name    : $FUNCTIONAPP_NAME
Resource group       : $RESOURCE_GROUP
Subscription ID      : $SUBSCRIPTION_ID

CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID must be added manually
from the Cloudflare dashboard — they cannot be generated from Azure.

  CLOUDFLARE_API_TOKEN:
    Cloudflare → My Profile → API Tokens → Create Token
    → Edit zone DNS template → scope to yumethathukorala.com

  CLOUDFLARE_ZONE_ID:
    Cloudflare → yumethathukorala.com → Overview → Zone ID (right sidebar)

=============================================================================
EOF

echo ""
echo "============================================="
echo " All resources created successfully."
echo "============================================="
echo ""
echo " Secret values saved to: $OUTPUT_FILE"
echo ""
echo " SWA hostname : $SWA_HOSTNAME"
echo " Cosmos endpoint: $COSMOS_ENDPOINT"
echo ""
echo " IMPORTANT: Delete $OUTPUT_FILE after"
echo " adding secrets to GitHub. Do not commit it."
echo ""
echo "============================================="
echo " Next steps"
echo "============================================="
echo ""
echo " 1. Download $OUTPUT_FILE from Cloud Shell"
echo "    (Cloud Shell toolbar → Upload/Download → Download)"
echo " 2. Add each secret to GitHub"
echo " 3. Add CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID manually"
echo " 4. Delete $OUTPUT_FILE"
echo " 5. Push to main to trigger the first deploy"
echo ""
