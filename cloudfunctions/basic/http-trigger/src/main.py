import os

import functions_framework
from flask import jsonify


@functions_framework.http
def main(request):
    function_name = os.environ.get("FUNCTION_NAME")
    request_json = request.get_json(silent=True)
    example_data = request_json["example_data"]
    return jsonify({"function_name": function_name, "example_data": example_data})
