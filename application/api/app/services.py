import json
import uuid
from datetime import UTC, datetime
from urllib.parse import quote_plus

import boto3
import psycopg
import redis.asyncio as redis
from botocore.config import Config

from .models import ItemCreate, JobCreate
from .settings import Settings


class ServiceConfigurationError(RuntimeError):
    pass


def _aws_client(service: str, settings: Settings):
    return boto3.client(
        service,
        region_name=settings.aws_region,
        endpoint_url=settings.aws_endpoint_url,
        config=Config(retries={"max_attempts": 3, "mode": "standard"}),
    )


async def create_item(settings: Settings, item: ItemCreate) -> dict:
    database_url = settings.database_url
    if not database_url and settings.database_secret and settings.rds_host:
        secret = json.loads(settings.database_secret)
        username = quote_plus(secret["username"])
        password = quote_plus(secret["password"])
        database_url = (
            f"postgresql://{username}:{password}@{settings.rds_host}:5432/"
            f"{settings.database_name}"
        )
    if not database_url:
        raise ServiceConfigurationError("DATABASE_URL is not configured")
    async with await psycopg.AsyncConnection.connect(database_url) as connection:
        await connection.execute(
            """
            CREATE TABLE IF NOT EXISTS items (
                id UUID PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT,
                created_at TIMESTAMPTZ NOT NULL
            )
            """
        )
        item_id = uuid.uuid4()
        created_at = datetime.now(UTC)
        await connection.execute(
            "INSERT INTO items (id, name, description, created_at) VALUES (%s, %s, %s, %s)",
            (item_id, item.name, item.description, created_at),
        )
        await connection.commit()
    return {"id": str(item_id), "name": item.name, "description": item.description}


async def check_redis(settings: Settings) -> bool:
    redis_url = settings.redis_url
    if not redis_url and settings.redis_host and settings.redis_auth_token:
        redis_url = f"rediss://:{quote_plus(settings.redis_auth_token)}@{settings.redis_host}:6379/0"
    if not redis_url:
        return False
    client = redis.from_url(redis_url, decode_responses=True)
    try:
        return bool(await client.ping())
    finally:
        await client.aclose()


def submit_job(settings: Settings, job: JobCreate) -> dict:
    if not settings.sqs_queue_url:
        raise ServiceConfigurationError("SQS_QUEUE_URL is not configured")
    job_id = str(uuid.uuid4())
    body = {
        "job_id": job_id,
        "created_at": datetime.now(UTC).isoformat(),
        "status": "queued",
        **job.model_dump(),
    }
    request = {
        "QueueUrl": settings.sqs_queue_url,
        "MessageBody": json.dumps(body),
    }
    if settings.sqs_queue_url.endswith(".fifo"):
        request["MessageGroupId"] = job_id
    _aws_client("sqs", settings).send_message(**request)
    return body


def get_job(settings: Settings, job_id: str) -> dict | None:
    if not settings.dynamodb_table_name:
        raise ServiceConfigurationError("DYNAMODB_TABLE_NAME is not configured")
    response = _aws_client("dynamodb", settings).query(
        TableName=settings.dynamodb_table_name,
        KeyConditionExpression="job_id = :job_id",
        ExpressionAttributeValues={":job_id": {"S": job_id}},
        ScanIndexForward=False,
        Limit=1,
    )
    return response.get("Items", [None])[0] if response.get("Items") else None


def create_upload_url(settings: Settings, object_key: str, content_type: str) -> str:
    if not settings.s3_bucket_name:
        raise ServiceConfigurationError("S3_BUCKET_NAME is not configured")
    return _aws_client("s3", settings).generate_presigned_url(
        "put_object",
        Params={
            "Bucket": settings.s3_bucket_name,
            "Key": object_key,
            "ContentType": content_type,
        },
        ExpiresIn=900,
    )
