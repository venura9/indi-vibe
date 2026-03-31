# Azure Indie Artist Platform

A Feature.fm alternative for indie musicians. Build-in-public YouTube series.
Talk: Vibing the Indie — Azure Builders Melbourne.

## Pilot artist
- Artist: Yumeth Athukorala
- Release: Deck of Cards
- Slug: yumethvoicetales
- Smart link: listen.yumethathukorala.com

## Stack
- Frontend: React + TypeScript + Vite (Azure Static Web Apps)
- API: Python 3.11, Azure Functions v2 programming model
- Database: Cosmos DB (serverless, Free Tier)
- CI/CD: GitHub Actions
- DNS: Cloudflare (yumethathukorala.com zone)

## Azure resource names
- Resource group: rg-indie-artist-platform
- Static Web App: swa-indie-artist-platform (eastasia — Free tier limitation)
- Function App: func-indie-artist-platform (australiaeast)
- Storage account: stindieartistpltfrm (australiaeast)
- Cosmos DB account: cosmos-indie-artist-platform (australiaeast)
- Database: indie-artist-db
- Container: smartlinks (partition key: /id)
- Service principal: sp-indie-artist-platform

## GitHub Actions secrets
- AZURE_CREDENTIALS — service principal JSON (do not use publish profiles)
- AZURE_STATIC_WEB_APPS_API_TOKEN — SWA deployment token
- COSMOS_ENDPOINT — Cosmos DB URI
- COSMOS_KEY — Cosmos DB primary key
- COSMOS_DB — value: indie-artist-db
- COSMOS_CONTAINER — value: smartlinks
- CLOUDFLARE_API_TOKEN — DNS edit permission on yumethathukorala.com
- CLOUDFLARE_ZONE_ID — yumethathukorala.com zone ID

Note: AZURE_FUNCTIONAPP_PUBLISH_PROFILE is NOT used.
Function App deploys via az functionapp deployment source config-zip
using AZURE_CREDENTIALS. Publish profiles are not good practice —
they are long-lived, unscoped, and not auditable.

## Conventions
- No publish profiles — always use AZURE_CREDENTIALS with Azure CLI
- Python dependencies installed into .python_packages/lib/site-packages
  and bundled into zip for Function App deployment
- No ORM, no heavy SDK abstractions — keep it readable on camera
- simple-icons for all platform logos — no inline SVG path blobs
- Mobile-first, dark playing card aesthetic
- Do NOT add GH_TOKEN as a secret — use secrets.GITHUB_TOKEN
- SWA Standard SKU required to link Function App backend via proxy
  Current setup uses Free SKU — Function App called directly or via zip deploy
- Slug "yumethvoicetales" is used as URL param, Cosmos id, and partition key

## Phase status
- Phase 1 (GitHub Pages): COMPLETE — github.com/venura9/deck-of-cards-gh-pages
- Phase 2a (Azure SWA + Functions, hardcoded data): IN PROGRESS
- Phase 2b (Add Cosmos DB): NOT STARTED
