# Indi Vibe

A Feature.fm alternative for indie musicians — Phase 2b (Cosmos DB backing).

## Live

[listen.yumethathukorala.com](https://listen.yumethathukorala.com/yumethvoicetales)

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | React 18 + TypeScript + Vite |
| API | Python 3.11, Azure Functions v2 |
| Database | Azure Cosmos DB (serverless, Free Tier) |
| Hosting | Azure Static Web Apps |
| CI/CD | GitHub Actions |
| Custom domain | listen.yumethathukorala.com (Cloudflare DNS) |

## Infrastructure

| Resource | Name | Tier | Region |
|---|---|---|---|
| Resource group | rg-indie-artist-platform | — | australiaeast |
| Static Web App | swa-indie-artist-platform | Free | eastasia |
| Function App | func-indie-artist-platform | Consumption | australiaeast |
| App Service Plan | plan-indie-artist-platform | Y1 (Linux) | australiaeast |
| Storage Account | stindieartistplatform | Standard LRS | australiaeast |
| Cosmos DB account | cosmos-indie-artist-platform | Serverless / Free Tier | australiaeast |
| Cosmos DB database | indie-artist-db | — | — |
| Cosmos DB container | smartlinks (partition key: /id) | — | — |

## GitHub Actions Secrets Required

| Secret | Source |
|---|---|
| `AZURE_CREDENTIALS` | `az ad sp create-for-rbac` JSON output |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | Azure portal → swa-indie-artist-platform → Deployment token |
| `CLOUDFLARE_API_TOKEN` | Cloudflare → My Profile → API Tokens |
| `CLOUDFLARE_ZONE_ID` | Cloudflare → yumethathukorala.com → Overview |
| `COSMOS_ENDPOINT` | `az cosmosdb show --query documentEndpoint` |
| `COSMOS_KEY` | `az cosmosdb keys list --query primaryMasterKey` |
| `COSMOS_DB` | `indie-artist-db` |
| `COSMOS_CONTAINER` | `smartlinks` |

## Cosmos DB Setup

Run once to provision the database resources:

```bash
# Create Cosmos DB account (serverless, Free Tier)
# Remove --enable-free-tier true if you already have a Free Tier account in this subscription
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

# Get endpoint → COSMOS_ENDPOINT secret
az cosmosdb show \
  --name cosmos-indie-artist-platform \
  --resource-group rg-indie-artist-platform \
  --query documentEndpoint -o tsv

# Get primary key → COSMOS_KEY secret
az cosmosdb keys list \
  --name cosmos-indie-artist-platform \
  --resource-group rg-indie-artist-platform \
  --query primaryMasterKey -o tsv
```

After adding the four Cosmos secrets to GitHub Actions, trigger the **Seed Cosmos DB** workflow
(`Actions → Seed Cosmos DB → Run workflow`) to insert the pilot document.

> **Note:** The frontend required zero changes in this phase. The response shape is identical
> so listen.yumethathukorala.com continues working throughout the migration with zero downtime.

## Local Development

### Frontend
```bash
npm install
npm run dev
```

### API
```bash
cd api
pip install -r requirements.txt
# Fill in COSMOS_* values in api/local.settings.json first
func start
```

## Project Structure

```
/
├── src/                    React + TypeScript frontend
├── public/                 Static assets
├── api/                    Python Azure Functions
│   ├── function_app.py     All API routes (Cosmos DB-backed)
│   ├── seed.py             One-shot seed script
│   ├── requirements.txt
│   └── local.settings.json
├── .github/workflows/      CI/CD pipelines
│   ├── deploy-frontend.yml
│   ├── deploy-api.yml
│   └── seed.yml            Manual Cosmos DB seed workflow
├── staticwebapp.config.json SWA routing
├── vite.config.ts
├── index.html
├── package.json
└── tsconfig.json
```
