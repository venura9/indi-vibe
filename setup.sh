#!/bin/bash
# =============================================================================
# Azure Indie Artist Platform — Resume Script
# Run this in GitHub Codespaces or Azure Cloud Shell
#
# Picks up from where setup.sh left off:
#   - Resource group       ✅ done
#   - Storage account      ✅ done
#   - Function App         ✅ done
#   - Static Web App       ✅ done (but wrong SKU — will upgrade)
#   - Link SWA + Function  ❌ failed — fixing now
#   - Cosmos DB            ❌ not yet done
#   - Service principal    ❌ not yet done
#   - Capture secrets      ❌ not yet done
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# CONFIG
# -----------------------------------------------------------------------------
SUBSCRIPTION_ID="aae8ff4c-3790-49b6-8fe0-2e3144a297d2"
RESOURCE_GROUP="rg-indie-artist-platform"
LOCATION="australiaeast"
SWA_LOCATION="eastasia"

FUNCTIONAPP_NAME="func-indie-artist-platform"
STORAGE_ACCOUNT="stindieartistpltfrm"
SWA_NAME="swa-indie-artist-platform"
COSMOS_ACCOUNT="cosmos-indie-artist-platform"
COSMOS_DB="indie-artist-db"
COSMOS_CONTAINER="smartlinks"
SP_NAME="sp-indie-artist-platform"
GITHUB_REPO="venura9/indie-artist-platform"

echo ""
echo "============================================="
echo " Azure Indie Artist Platform — Resume Script"
echo "============================================="
echo ""

# -----------------------------------------------------------------------------
# UPGRADE SWA TO STANDARD SKU
# (required for linked backend / Function App proxy)
# -----------------------------------------------------------------------------
echo ">>> Upgrading Static Web App to Standard SKU..."
az staticwebapp update \
  --name "$SWA_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --sku Standard \
  --output none
echo "    Done. (~$9 USD/month — disable when not needed)"

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
# COSMOS DB
# -----------------------------------------------------------------------------
echo ">>> Creating Cosmos DB account (serverless)..."
echo "    Note: --enable-free-tier true limited to one account per subscription."
echo "    If this fails with Free Tier error, remove that flag and rerun."

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
# SERVICE PRINCIPAL
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
SWA SKU              : Standard (~$9 USD/month)
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
 Cost reminder
=============================================================================

Azure Static Web Apps Standard tier costs ~$9 USD/month.
To avoid charges when not actively developing:

  az staticwebapp update \
    --name $SWA_NAME \
    --resource-group $RESOURCE_GROUP \
    --sku Free

Note: downgrading to Free will unlink the Function App backend.
Upgrade back to Standard before next deploy:

  az staticwebapp update \
    --name $SWA_NAME \
    --resource-group $RESOURCE_GROUP \
    --sku Standard

=============================================================================
 Next steps
=============================================================================

1. Open github-secrets.txt and add each secret to GitHub
2. Add CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID manually
3. Delete github-secrets.txt — do not commit it
4. Push to main to trigger the first deploy
5. Visit $SWA_HOSTNAME to confirm the site is live
6. Then point listen.yumethathukorala.com via Cloudflare CNAME

=============================================================================
EOF

echo ""
echo "============================================="
echo " All done."
echo "============================================="
echo ""
echo " SWA hostname    : $SWA_HOSTNAME"
echo " Cosmos endpoint : $COSMOS_ENDPOINT"
echo " Secret values   : $OUTPUT_FILE"
echo ""
echo " IMPORTANT: Delete $OUTPUT_FILE after"
echo " adding secrets to GitHub. Do not commit it."
echo ""
