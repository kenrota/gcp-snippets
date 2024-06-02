import argparse
import json
from concurrent import futures
from datetime import datetime
from google.cloud import pubsub_v1


def send_messages(project_id: str, topic_name: str, num_messages: int) -> None:
    topic_path = f"projects/{project_id}/topics/{topic_name}"
    batch_settings = pubsub_v1.types.BatchSettings()
    publisher = pubsub_v1.PublisherClient(batch_settings)
    publish_at = datetime.now().isoformat()
    print(f"{publish_at=}")

    publish_futures = []
    for i in range(num_messages):
        message_obj = {
            "publish_at": publish_at,
            "data": f"hello {i}",
        }
        message = json.dumps(message_obj).encode("utf-8")
        publish_future = publisher.publish(topic_path, message)
        publish_futures.append(publish_future)

    futures.wait(publish_futures, return_when=futures.ALL_COMPLETED)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--project_id", type=str)
    parser.add_argument("--topic_name", type=str)
    parser.add_argument("--num_messages", type=int)
    args = parser.parse_args()

    send_messages(args.project_id, args.topic_name, args.num_messages)
