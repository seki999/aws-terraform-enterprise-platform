import logging
import os
import time

import boto3
from common_logging import log_event

logger = logging.getLogger()
logger.setLevel(logging.INFO)
dynamodb = boto3.client("dynamodb")


def handler(event: dict, _context: object) -> dict:
    job_id = event["job_id"]
    created_at = event["created_at"]
    try:
        dynamodb.put_item(
            TableName=os.environ["TABLE_NAME"],
            Item={
                "job_id": {"S": job_id},
                "created_at": {"S": created_at},
                "status": {"S": "completed"},
                "expires_at": {"N": str(int(time.time()) + 86400 * 30)},
            },
            ConditionExpression="attribute_not_exists(job_id)",
        )
    except Exception:
        logger.exception("job_persistence_failed")
        raise
    log_event(logger, "job_completed", job_id=job_id)
    return {**event, "status": "completed"}
