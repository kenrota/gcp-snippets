import os
import base64
import json

import functions_framework
from google.cloud import storage
from cloudevents.http.event import CloudEvent


def upload_data(data, bucket_name, dest_blob_name):
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    json_data = json.dumps(data)
    blob = bucket.blob(dest_blob_name)
    blob.upload_from_string(json_data, content_type="application/json")


@functions_framework.cloud_event
def main(cloud_event: CloudEvent):
    data_raw = base64.b64decode(cloud_event.data["message"]["data"]).decode("utf-8")
    data = json.loads(data_raw)
    upload_data(
        data=json.loads(data_raw),
        bucket_name=os.environ.get("RESULT_BUCKET_NAME"),
        dest_blob_name=f"test/data_{data['task_id']}.json",
    )
    return "ok"
