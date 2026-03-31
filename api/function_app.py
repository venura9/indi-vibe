import azure.functions as func
import json

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

ARTIST_DATA = {
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
}


@app.route(route="links/{slug}", methods=["GET"])
def get_links(req: func.HttpRequest) -> func.HttpResponse:
    slug = req.route_params.get("slug", "")
    headers = {"Access-Control-Allow-Origin": "*", "Content-Type": "application/json"}

    if slug == "yumethvoicetales":
        return func.HttpResponse(json.dumps(ARTIST_DATA), status_code=200, headers=headers)

    return func.HttpResponse(
        json.dumps({"error": "not found"}), status_code=404, headers=headers
    )
