# Prompt 2a — Azure SWA + Python Functions (hardcoded data, new repo)
 
## Azure Resource Setup
 
Run these commands once before deploying. All resources go into `australiaeast`.
 
```bash
# Create resource group
az group create \
  --name rg-indie-artist-platform \
  --location australiaeast
 
# Create App Service Plan (Consumption — Linux)
az functionapp plan create \
  --name plan-indie-artist-platform \
  --resource-group rg-indie-artist-platform \
  --location australiaeast \
  --sku Y1 \
  --is-linux
 
# Create Storage Account (required by Function App)
az storage account create \
  --name stindieartistplatform \
  --resource-group rg-indie-artist-platform \
  --location australiaeast \
  --sku Standard_LRS
 
# Create Function App (Python 3.11)
az functionapp create \
  --name func-indie-artist-platform \
  --resource-group rg-indie-artist-platform \
  --plan plan-indie-artist-platform \
  --storage-account stindieartistplatform \
  --runtime python \
  --runtime-version 3.11 \
  --os-type linux \
  --functions-version 4
 
# Create Static Web App
az staticwebapp create \
  --name swa-indie-artist-platform \
  --resource-group rg-indie-artist-platform \
  --location eastasia \
  --sku Free
 
# Link Function App to Static Web App
az staticwebapp backends link \
  --name swa-indie-artist-platform \
  --resource-group rg-indie-artist-platform \
  --backend-resource-id $(az functionapp show \
    --name func-indie-artist-platform \
    --resource-group rg-indie-artist-platform \
    --query id -o tsv) \
  --backend-region australiaeast
 
# Create service principal for GitHub Actions
az ad sp create-for-rbac \
  --name sp-indie-artist-platform \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/rg-indie-artist-platform \
  --sdk-auth
# Copy the full JSON output — this is AZURE_CREDENTIALS secret
```
 
---
 
## GitHub Actions Secrets
 
Add these to the new repo under Settings → Secrets and variables → Actions:
 
| Secret | How to get it |
|---|---|
| `AZURE_CREDENTIALS` | JSON output from `az ad sp create-for-rbac` above |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | Azure portal → swa-indie-artist-platform → Deployment → Manage deployment token |
| `CLOUDFLARE_API_TOKEN` | Cloudflare dashboard → My Profile → API Tokens → Create Token → Edit zone DNS template |
| `CLOUDFLARE_ZONE_ID` | Cloudflare dashboard → yumethathukorala.com → Overview → Zone ID |

Note: Do NOT add GH_TOKEN — use secrets.GITHUB_TOKEN which is available
automatically in all GitHub Actions workflows.

Note: `AZURE_FUNCTIONAPP_PUBLISH_PROFILE` is NOT used. Function App deploys via
`az functionapp deployment source config-zip` using `AZURE_CREDENTIALS`.
Publish profiles are not good practice — they are long-lived, unscoped, and not auditable.
 
---
 
## Copilot Prompt
 
```
I'm building the Azure Indie Artist Platform — a Feature.fm alternative for indie
musicians — as a build-in-public YouTube series. This is phase 1 — frontend and
API only, no database yet. Data is hardcoded in the API so I can demo immediately.
 
This is a brand new repo. The existing repo
https://github.com/venura9/deck-of-cards-gh-pages is a separate project
(GitHub Pages version) and should not be referenced or modified.
 
**Tech stack:**
- Frontend: React + TypeScript + Vite (Azure Static Web Apps)
- API: Python 3.11, Azure Functions v2 programming model
- CI/CD: GitHub Actions
- Custom domain: listen.yumethathukorala.com (Cloudflare DNS)
 
**Azure resource names (already created):**
- Resource group: rg-indie-artist-platform
- Static Web App: swa-indie-artist-platform
- Function App: func-indie-artist-platform
- Region: australiaeast
 
**Pilot data — Yumeth Athukorala, "Deck of Cards":**
Slug: yumethvoicetales
Cover art: https://imagestore.ffm.to/link/696ebf792e00006b008c5d89/697708312f000016007f72e7_0594eda9b61e8dacb87e1abc2f35d32d.jpeg
Streaming links:
  - Spotify: https://open.spotify.com/album/7tAImO0jC2X682dNB4a4YI
  - Apple Music: https://geo.music.apple.com/us/album/deck-of-cards-single/1866379749?app=music
  - TIDAL: http://www.tidal.com/album/486860762
  - Deezer: https://www.deezer.com/album/890410182
  - Amazon Music: https://music.amazon.com/albums/B0GDXLTZPF
  - YouTube: https://www.youtube.com/watch?v=1KGntXXwfBA
  - YouTube Music: https://music.youtube.com/playlist?list=OLAK5uy_nn8bF0caPTCvoS0r8_mCcXV9dHpW00I6I
Social links:
  - YouTube: https://youtube.com/@yumeth.voicetales
  - Spotify: https://open.spotify.com/artist/48fSdVyiuRXmjGSOCy8aVD
  - TikTok: https://www.tiktok.com/@yumeth.voicetales/
  - Facebook: https://www.facebook.com/yumeth.voicetales/
  - Instagram: https://www.instagram.com/yumeth.voicetales
 
**What I need built:**
 
1. Repo structure
   /
     src/                      React + TypeScript frontend
     public/                   Static assets
     api/                      Python Azure Functions
     .github/workflows/        CI/CD pipelines
     staticwebapp.config.json  SWA routing config
     vite.config.ts            base: '/'
     index.html
     package.json
     tsconfig.json
     .gitignore
     README.md
 
2. /api/ — Python Azure Functions v2
   File layout:
     /api/
       function_app.py       (single file, all routes here)
       requirements.txt      (azure-functions only for now)
       local.settings.json   (template, no real secrets)
 
   Routes:
     GET /api/links/{slug}
     - If slug == "yumethvoicetales" return the hardcoded dict below
     - Otherwise return 404 + {"error": "not found"}
     - Set CORS header: Access-Control-Allow-Origin: *
 
   Hardcoded response:
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
       }
     }
 
   Keep it simple — no classes, no abstraction. Straight top-to-bottom Python.
 
3. staticwebapp.config.json — repo root
   - Route /api/* proxied to linked Function App
   - Fallback route to index.html for SPA routing
 
4. React + TypeScript frontend
   - SmartLinkPage component: fetches GET /api/links/{slug},
     renders cover art, platform buttons, social icons
   - Slug read from URL param: /:slug
   - Use simple-icons npm package for platform logos:
       npm install simple-icons
     Import: siSpotify, siApplemusic, siTidal, siDeezer,
             siAmazonmusic, siYoutube, siYoutubemusic
     Render each as: <svg viewBox="0 0 24 24"><path d={icon.path}/></svg>
   - Playing card dark aesthetic, mobile-first
   - vite.config.ts: base: '/'
 
5. GitHub Actions workflows:
 
   a. .github/workflows/deploy-frontend.yml
      - Trigger: push to main, paths: ['src/**', 'public/**',
        'index.html', 'vite.config.ts', 'staticwebapp.config.json']
      - Steps:
          i.  Azure login using AZURE_CREDENTIALS secret
          ii. npm ci && npm run build
          iii.Deploy to swa-indie-artist-platform
              using Azure/static-web-apps-deploy@v1
              with AZURE_STATIC_WEB_APPS_API_TOKEN
          iv. Cloudflare DNS step (runs after successful SWA deploy):
              - Use Azure CLI to get the SWA default hostname:
                az staticwebapp show \
                  --name swa-indie-artist-platform \
                  --resource-group rg-indie-artist-platform \
                  --query "defaultHostname" -o tsv
              - Use Cloudflare API directly via curl (no third-party actions)
              - Check if CNAME record for listen.yumethathukorala.com exists
              - Create or update it to point to the SWA default hostname
              - Proxy status: DNS-only (orange cloud OFF)
              - Idempotent — safe to run on every push
 
   b. .github/workflows/deploy-api.yml
      - Trigger: push to main, paths: ['api/**']
      - Steps:
          i.   Azure login using AZURE_CREDENTIALS secret
          ii.  pip install -r api/requirements.txt \
                 --target api/.python_packages/lib/site-packages
          iii. Zip the api/ directory and deploy via:
               az functionapp deployment source config-zip \
                 --name func-indie-artist-platform \
                 --resource-group rg-indie-artist-platform \
                 --src api.zip
      - Do NOT use azure/functions-action@v1 with a publish profile.
        AZURE_FUNCTIONAPP_PUBLISH_PROFILE is not used — it is long-lived,
        unscoped, and not auditable.
 
   Both workflows use secrets.GITHUB_TOKEN where needed —
   do not add GH_TOKEN as a separate secret, it is not required.
 
6. Required GitHub Actions secrets (all new — fresh repo):
   - AZURE_CREDENTIALS
   - AZURE_STATIC_WEB_APPS_API_TOKEN
   - CLOUDFLARE_API_TOKEN
   - CLOUDFLARE_ZONE_ID
 
7. Infrastructure — document in README:
   - Resource group: rg-indie-artist-platform
   - Azure Static Web App: swa-indie-artist-platform, Free tier, australiaeast
   - Azure Function App: func-indie-artist-platform,
     Consumption plan, Python 3.11, Linux, australiaeast
   - Custom domain: listen.yumethathukorala.com
 
No database, no environment variables beyond what is listed above.
The goal is the smallest possible working surface area —
deploy, visit listen.yumethathukorala.com, see the smart link page. That's it.
```
