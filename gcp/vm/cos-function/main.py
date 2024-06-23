import flask
import functions_framework
import logging

logger = logging.getLogger("sample")
logging.basicConfig(level=logging.DEBUG)


@functions_framework.http
def hello(request: flask.Request) -> flask.typing.ResponseReturnValue:
    logger.debug(f"Request method: {request.method}")
    return "hello"
