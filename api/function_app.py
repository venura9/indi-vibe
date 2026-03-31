import azure.functions as func
import json
import os

from azure.cosmos import CosmosClient
from azure.cosmos.exceptions import CosmosResourceNotFoundError

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

client = CosmosClient(
    url=os.environ["COSMOS_ENDPOINT"],
    credential=os.environ["COSMOS_KEY"],
)
container = (
    client
    .get_database_client(os.environ["COSMOS_DB"])
    .get_container_client(os.environ["COSMOS_CONTAINER"])
)


@app.route(route="links/{slug}", methods=["GET"])
def get_links(req: func.HttpRequest) -> func.HttpResponse:
    slug = req.route_params.get("slug", "")
    headers = {"Access-Control-Allow-Origin": "*", "Content-Type": "application/json"}

    try:
        item = container.read_item(item=slug, partition_key=slug)
        return func.HttpResponse(json.dumps(item), status_code=200, headers=headers)
    except CosmosResourceNotFoundError:
        return func.HttpResponse(
            json.dumps({"error": "not found"}), status_code=404, headers=headers
        )
