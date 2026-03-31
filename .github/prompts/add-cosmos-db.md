# Prompt 2b — Add Cosmos DB (run after 2a is live and demoed)
 
## Azure Resource Setup
 
Run these commands once. Resources are added to the existing
`rg-indie-artist-platform` resource group.
 
```bash
# Create Cosmos DB account (serverless, Free Tier)
# Note: Free Tier is limited to one account per subscription.
# Remove --enable-free-tier true if you already have one.
az cosmosdb create \
  --name cosmos-indie-artist-platform \
  --resource-group rg-indie-artist-platform \
  --locations regionName=australiaeast \
  --capabilities EnableServerless \
  --enable-free-tier true
 
# Create database
az cosmosdb sql database create \
  --account-name cosmos-indie-artist-platform \
  --resource-group rg-indie-artist-platform \
  --name indie-artist-db
 
# Create container
az cosmosdb sql container create \
  --account-name cosmos-indie-artist-platform \
  --resource-group rg-indie-artist-platform \
  --database-name indie-artist-db \
  --name smartlinks \
  --partition-key-path /id
 
# Get Cosmos DB endpoint and key for GitHub Actions secrets
az cosmosdb show \
  --name cosmos-indie-artist-platform \
  --resource-group rg-indie-artist-platform \
  --query documentEndpoint -o tsv
# Copy output → COSMOS_ENDPOINT secret
 
az cosmosdb keys list \
  --name cosmos-indie-artist-platform \
  --resource-group rg-indie-artist-platform \
  --query primaryMasterKey -o tsv
# Copy output → COSMOS_KEY secret
```
 
---
 
## GitHub Actions Secrets
 
Add these four new secrets to the repo under
Settings → Secrets and variables → Actions:
 
| Secret | Value |
|---|---|
| `COSMOS_ENDPOINT` | Output of `az cosmosdb show --query documentEndpoint` above |
| `COSMOS_KEY` | Output of `az cosmosdb keys list --query primaryMasterKey` above |
| `COSMOS_DB` | `indie-artist-db` |
| `COSMOS_CONTAINER` | `smartlinks` |
 
Already present — do not touch:
 
| Secret | Status |
|---|---|
| `AZURE_CREDENTIALS` | Leave as-is |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | Leave as-is |
| `AZURE_FUNCTIONAPP_PUBLISH_PROFILE` | Leave as-is |
| `CLOUDFLARE_API_TOKEN` | Leave as-is |
| `CLOUDFLARE_ZONE_ID` | Leave as-is |
 
---
 
## Copilot Prompt
 
```
The Azure Indie Artist Platform frontend and API are already built and deployed
using Azure Static Web Apps + Azure Functions (Python 3.11 v2 model).
The API currently returns hardcoded data for the "yumethvoicetales" slug.
The domain is listen.yumethathukorala.com.
 
**What already exists (do not recreate or modify):**
- src/                          React + TypeScript frontend (no changes needed)
- public/                       Static assets (no changes needed)
- staticwebapp.config.json      SWA routing (no changes needed)
- vite.config.ts                (no changes needed)
- .github/workflows/deploy-frontend.yml  (no changes needed)
- .github/workflows/deploy-api.yml       (will be updated)
- api/function_app.py           (will be updated)
- api/requirements.txt          (will be updated)
- api/local.settings.json       (will be updated)
 
**Azure resources already exist:**
- Resource group: rg-indie-artist-platform
- Static Web App: swa-indie-artist-platform (australiaeast)
- Function App: func-indie-artist-platform (australiaeast)
- Cosmos DB account: cosmos-indie-artist-platform (australiaeast)
- Cosmos DB database: indie-artist-db
- Cosmos DB container: smartlinks (partition key: /id)
 
**What I need added:**
 
1. Seed script — /api/seed.py
   Standalone script, run once locally or via workflow_dispatch.
   Uses azure-cosmos SDK to insert the pilot document:
     {
       "id": "yumethvoicetales",
       "artistName": "Yumeth Athukorala",
       "releaseTitle": "Deck of Cards",
       "coverArtUrl": "https://imagestore.ffm.to/link/696ebf792e00006b008c5d89/697708312f000016007f72e7_0594eda9b61e8dacb87e1abc2f35d32d.jpeg",
       "platforms": {
         "Spotify": "https://open.spotify.com/album/7tAImO0jC2X682dNB4a4YI",
         "Apple Music": "https://geo.music.apple.com/us/album/deck-of-cards-single/1866379749?app=music",
         "TIDAL": "http://www.tidal.com/album/486860762",
         "Deezer": "https://www.deezer.com/album/890410182",
         "Amazon Music": "https://music.amazon.com/albums/B0GDXLTZPF",
         "YouTube": "https://www.youtube.com/watch?v=1KGntXXwfBA",
         "YouTube Music": "https://music.youtube.com/playlist?list=OLAK5uy_nn8bF0caPTCvoS0r8_mCcXV9dHpW00I6I"
       },
       "socials": {
         "YouTube": "https://youtube.com/@yumeth.voicetales",
         "Spotify": "https://open.spotify.com/artist/48fSdVyiuRXmjGSOCy8aVD",
         "TikTok": "https://www.tiktok.com/@yumeth.voicetales/",
         "Facebook": "https://www.facebook.com/yumeth.voicetales/",
         "Instagram": "https://www.instagram.com/yumeth.voicetales"
       },
       "clickCount": 0,
       "createdAt": "<ISO8601 timestamp at time of seeding>",
       "updatedAt": "<ISO8601 timestamp at time of seeding>"
     }
 
   Reads config from environment variables:
     COSMOS_ENDPOINT
     COSMOS_KEY
     COSMOS_DB        (indie-artist-db)
     COSMOS_CONTAINER (smartlinks)
 
   Add .github/workflows/seed.yml:
   - Trigger: workflow_dispatch only (manual run)
   - Steps:
       i.  Azure login using AZURE_CREDENTIALS
       ii. pip install azure-cosmos
       iii.Run python api/seed.py
   - Uses the same four Cosmos secrets listed below
 
2. Update /api/function_app.py
   Replace the hardcoded dict with a Cosmos DB lookup:
 
   from azure.cosmos import CosmosClient
   from azure.cosmos.exceptions import CosmosResourceNotFoundError
 
   client = CosmosClient(
     url=os.environ["COSMOS_ENDPOINT"],
     credential=os.environ["COSMOS_KEY"]
   )
   container = (
     client
     .get_database_client(os.environ["COSMOS_DB"])
     .get_container_client(os.environ["COSMOS_CONTAINER"])
   )
 
   In the route handler:
   - Call container.read_item(item=slug, partition_key=slug)
   - Return 200 + item as JSON if found
   - Catch CosmosResourceNotFoundError, return 404 +
     {"error": "not found"}
   - Keep the same response shape — frontend does not change at all
 
   Do not restructure the file. Do not rename any existing functions.
   Do not change the response shape.
 
3. Update /api/requirements.txt
   Add: azure-cosmos
 
4. Update /api/local.settings.json template
   Add four Cosmos environment variables as empty placeholders:
     COSMOS_ENDPOINT
     COSMOS_KEY
     COSMOS_DB
     COSMOS_CONTAINER
 
5. Update .github/workflows/deploy-api.yml
   Add a step after Azure login to push Cosmos settings
   to the Function App:
 
   az functionapp config appsettings set \
     --name func-indie-artist-platform \
     --resource-group rg-indie-artist-platform \
     --settings \
       COSMOS_ENDPOINT=${{ secrets.COSMOS_ENDPOINT }} \
       COSMOS_KEY=${{ secrets.COSMOS_KEY }} \
       COSMOS_DB=${{ secrets.COSMOS_DB }} \
       COSMOS_CONTAINER=${{ secrets.COSMOS_CONTAINER }}
 
6. Required new GitHub Actions secrets:
   - COSMOS_ENDPOINT    (Azure portal → Cosmos account → Keys → URI)
   - COSMOS_KEY         (Azure portal → Cosmos account → Keys → Primary key)
   - COSMOS_DB          (value: indie-artist-db)
   - COSMOS_CONTAINER   (value: smartlinks)
 
   Already present, do not touch:
   - AZURE_CREDENTIALS
   - AZURE_STATIC_WEB_APPS_API_TOKEN
   - AZURE_FUNCTIONAPP_PUBLISH_PROFILE
   - CLOUDFLARE_API_TOKEN
   - CLOUDFLARE_ZONE_ID
 
7. Update README
   - Add "Cosmos DB setup" section with az CLI commands
   - Add four new secrets to the secrets table
   - Note that the frontend required zero changes in this phase
 
The frontend does not change at all in this prompt.
Only the API, its dependencies, its environment variables,
and the deploy pipeline change. The response shape stays
identical so listen.yumethathukorala.com continues working
throughout the migration with zero downtime.
```
