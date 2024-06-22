import os

import functions_framework
from flask import jsonify


@functions_framework.http
def main(request):
    request_json = request.get_json(silent=True)
    name = request_json["name"]
    example_env = os.environ.get("EXAMPLE_ENV")
    print(f"{example_env=}")
    return jsonify({"message": f"hello {name}!"})
