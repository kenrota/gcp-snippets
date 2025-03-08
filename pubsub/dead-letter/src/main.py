import functions_framework
from flask import Request, make_response, Response


@functions_framework.http
def main(request: Request) -> Response:
    print(f"{request.data=}")

    # デッドレターにメッセージ送信されるように、エラーを返す
    response = make_response("error", 500)
    response.headers["Content-Type"] = "text/plain"
    return response
