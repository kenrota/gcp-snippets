import os
import base64
import functions_framework
from cloudevents.http.event import CloudEvent
from google.cloud import storage
from google.api_core.exceptions import PreconditionFailed

_storage = storage.Client()
_IDEMPOTENCY_BUCKET = os.environ["IDEMPOTENCY_BUCKET"]


def _mark_as_processed(message_id: str) -> bool:
    bucket = _storage.bucket(_IDEMPOTENCY_BUCKET)
    blob = bucket.blob(f"pubsub/{message_id}")
    try:
        blob.upload_from_string(
            data="",
            content_type="text/plain",
            if_generation_match=0,  # Ensure the blob does not already exist
        )
        return True
    except PreconditionFailed:
        return False


@functions_framework.cloud_event
def main(cloud_event: CloudEvent):
    print(f"{cloud_event=}")

    message = cloud_event.data["message"]
    message_id = message["message_id"]
    print(f"{message_id=}")

    if not _mark_as_processed(message_id):
        print("Duplicate delivery detected. Skipping processing.")
        return

    data = base64.b64decode(message["data"]).decode("utf-8")
    print(f"{data=}")

    return
