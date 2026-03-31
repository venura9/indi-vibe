"""Seed script — run once to insert the pilot document into Cosmos DB.

Usage:
    COSMOS_ENDPOINT=... COSMOS_KEY=... COSMOS_DB=indie-artist-db \
    COSMOS_CONTAINER=smartlinks python api/seed.py
"""

import os
from datetime import datetime, timezone

from azure.cosmos import CosmosClient, PartitionKey

ENDPOINT = os.environ["COSMOS_ENDPOINT"]
KEY = os.environ["COSMOS_KEY"]
DB_NAME = os.environ["COSMOS_DB"]
CONTAINER_NAME = os.environ["COSMOS_CONTAINER"]

now = datetime.now(timezone.utc).isoformat()

document = {
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
        "YouTube Music": "https://music.youtube.com/playlist?list=OLAK5uy_nn8bF0caPTCvoS0r8_mCcXV9dHpW00I6I",
    },
    "socials": {
        "YouTube": "https://youtube.com/@yumeth.voicetales",
        "Spotify": "https://open.spotify.com/artist/48fSdVyiuRXmjGSOCy8aVD",
        "TikTok": "https://www.tiktok.com/@yumeth.voicetales/",
        "Facebook": "https://www.facebook.com/yumeth.voicetales/",
        "Instagram": "https://www.instagram.com/yumeth.voicetales",
    },
    "clickCount": 0,
    "createdAt": now,
    "updatedAt": now,
}

client = CosmosClient(url=ENDPOINT, credential=KEY)
container = (
    client
    .get_database_client(DB_NAME)
    .get_container_client(CONTAINER_NAME)
)

container.upsert_item(document)
print(f"Seeded document id={document['id']} at {now}")
