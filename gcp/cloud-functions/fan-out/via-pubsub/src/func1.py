import json
import os
from concurrent import futures
from datetime import datetime

import functions_framework
from google.cloud import pubsub_v1

# バッチメッセージング
# 参考ドキュメント: https://cloud.google.com/pubsub/docs/batch-messaging?hl=ja
batch_settings = pubsub_v1.types.BatchSettings(
    max_messages=5,
)


@functions_framework.http
def main(_request):
    topic_path = os.environ.get("REQ_TO_FUNC2_TOPIC")
    publisher = pubsub_v1.PublisherClient(batch_settings)
    publish_id = datetime.now().isoformat()
    print(f"{publish_id=}")

    publish_futures = []

    def callback(future: pubsub_v1.publisher.futures.Future) -> None:
        message_id = future.result()
        print(message_id)

    num_messages = 100
    for i in range(num_messages):
        message_obj = {
            "publish_id": publish_id,
            "task_id": i + 1,
            "data": "hello func2",
        }
        message = json.dumps(message_obj).encode("utf-8")
        publish_future = publisher.publish(topic_path, message)
        publish_future.add_done_callback(callback)
        publish_futures.append(publish_future)

    futures.wait(publish_futures, return_when=futures.ALL_COMPLETED)

    return publish_id
