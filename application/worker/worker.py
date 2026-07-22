import json
import logging
import os
import signal
import time
from datetime import UTC, datetime

import boto3

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"), format="%(message)s")
logger = logging.getLogger("platform-worker")
running = True


def stop(*_: object) -> None:
    global running
    running = False


def main() -> None:
    queue_url = os.environ["SQS_QUEUE_URL"]
    table_name = os.environ["DYNAMODB_TABLE_NAME"]
    region = os.getenv("AWS_REGION", "ap-northeast-1")
    sqs = boto3.client("sqs", region_name=region)
    dynamodb = boto3.client("dynamodb", region_name=region)

    while running:
        response = sqs.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=5,
            WaitTimeSeconds=20,
            VisibilityTimeout=60,
        )
        for message in response.get("Messages", []):
            try:
                body = json.loads(message["Body"])
                dynamodb.put_item(
                    TableName=table_name,
                    Item={
                        "job_id": {"S": body["job_id"]},
                        "created_at": {"S": body["created_at"]},
                        "status": {"S": "processed"},
                        "processed_at": {"S": datetime.now(UTC).isoformat()},
                    },
                    ConditionExpression="attribute_not_exists(job_id)",
                )
                sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=message["ReceiptHandle"])
                logger.info(json.dumps({"event": "job_processed", "job_id": body["job_id"]}))
            except Exception:
                logger.exception(json.dumps({"event": "job_failed"}))
        time.sleep(0.1)


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    main()

