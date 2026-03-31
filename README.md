# Indi Vibe

A Feature.fm alternative for indie musicians — Phase 1 (frontend + API, hardcoded data).

## Live

[listen.yumethathukorala.com](https://listen.yumethathukorala.com/yumethvoicetales)

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | React 18 + TypeScript + Vite |
| API | Python 3.11, Azure Functions v2 |
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

## GitHub Actions Secrets Required

| Secret | Source |
|---|---|
| `AZURE_CREDENTIALS` | `az ad sp create-for-rbac` JSON output |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | Azure portal → swa-indie-artist-platform → Deployment token |
| `AZURE_FUNCTIONAPP_PUBLISH_PROFILE` | Azure portal → func-indie-artist-platform → Get publish profile |
| `CLOUDFLARE_API_TOKEN` | Cloudflare → My Profile → API Tokens |
| `CLOUDFLARE_ZONE_ID` | Cloudflare → yumethathukorala.com → Overview |

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
func start
```

## Project Structure

```
/
├── src/                    React + TypeScript frontend
├── public/                 Static assets
├── api/                    Python Azure Functions
│   ├── function_app.py     All API routes
│   ├── requirements.txt
│   └── local.settings.json
├── .github/workflows/      CI/CD pipelines
├── staticwebapp.config.json SWA routing
├── vite.config.ts
├── index.html
├── package.json
└── tsconfig.json
```
