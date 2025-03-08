import functions_framework
from cloudevents.http.event import CloudEvent
from google.cloud import pubsub_v1
from google.api_core import retry
import os

NUM_BATCHES = 15
MAX_MESSAGES = 1000


def pull_messages(project_id: str, subscription_name: str) -> None:
    subscriber = pubsub_v1.SubscriberClient()
    subscription_path = subscriber.subscription_path(project_id, subscription_name)

    with subscriber:
        for n in range(NUM_BATCHES):
            response = subscriber.pull(
                # https://cloud.google.com/pubsub/quotas?hl=ja#resource_limits
                # 単項 pull レスポンス
                #   pull レスポンス内のメッセージの最大数: 1,000
                #   pull レスポンスの最大サイズ: 10 MB
                request={
                    "subscription": subscription_path,
                    "max_messages": MAX_MESSAGES,
                },
                retry=retry.Retry(deadline=300),
            )

            if len(response.received_messages) == 0:
                print(f"[{n}] No messages received.")
                continue
            else:
                ack_ids = []
                for received_message in response.received_messages:
                    ack_ids.append(received_message.ack_id)

                subscriber.acknowledge(
                    request={"subscription": subscription_path, "ack_ids": ack_ids}
                )

                print(f"[{n}] Acknowledged. {len(response.received_messages)=}")


@functions_framework.cloud_event
def main(cloud_event: CloudEvent) -> None:
    print(f"{cloud_event=}")
    project_id = os.environ.get("PROJECT_ID")
    subscription_name = os.environ.get("BUFFER_SUBSCRIPTION_NAME")

    pull_messages(project_id, subscription_name)
