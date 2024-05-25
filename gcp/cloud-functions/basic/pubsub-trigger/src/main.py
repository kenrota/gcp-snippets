import os
import base64
import functions_framework
from cloudevents.http.event import CloudEvent


@functions_framework.cloud_event
def main(cloud_event: CloudEvent):
    print(f"{cloud_event=}")
    example_env = os.environ.get("EXAMPLE_ENV")
    print(f"{example_env=}")
    data = base64.b64decode(cloud_event.data["message"]["data"]).decode("utf-8")
    print(f"{data=}")
