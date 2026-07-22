import json
import logging
import os
import uuid
from datetime import UTC, datetime

import boto3
from common_logging import log_event

logger = logging.getLogger()
logger.setLevel(logging.INFO)
sqs = boto3.client("sqs")


def response(status: int, body: dict) -> dict:
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body),
    }


def handler(event: dict, _context: object) -> dict:
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return response(400, {"error": "invalid JSON"})

    object_key = body.get("object_key")
    operation = body.get("operation", "inspect")
    if not isinstance(object_key, str) or not object_key.strip():
        return response(400, {"error": "object_key is required"})
    if operation not in {"inspect", "transform", "archive"}:
        return response(400, {"error": "unsupported operation"})

    job = {
        "job_id": str(uuid.uuid4()),
        "created_at": datetime.now(UTC).isoformat(),
        "status": "queued",
        "object_key": object_key,
        "operation": operation,
    }
    try:
        sqs.send_message(QueueUrl=os.environ["QUEUE_URL"], MessageBody=json.dumps(job))
    except Exception:
        logger.exception("job_enqueue_failed")
        return response(500, {"error": "job could not be queued"})
    log_event(logger, "job_validated", job_id=job["job_id"])
    return response(202, job)
