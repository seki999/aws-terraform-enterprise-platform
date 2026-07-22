import logging
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest

from .logging_config import configure_logging
from .models import ItemCreate, JobCreate, UploadRequest
from .services import (
    ServiceConfigurationError,
    check_redis,
    create_item,
    create_upload_url,
    get_job,
    submit_job,
)
from .settings import get_settings

settings = get_settings()
configure_logging(settings.log_level)
logger = logging.getLogger("platform-api")
requests_total = Counter("platform_api_requests_total", "Processed API requests", ["route"])


@asynccontextmanager
async def lifespan(_: FastAPI):
    logger.info("application_started")
    yield
    logger.info("application_stopped")


app = FastAPI(title="AWS Terraform Enterprise Platform API", version="1.0.0", lifespan=lifespan)


@app.get("/health")
async def health() -> dict:
    requests_total.labels(route="health").inc()
    return {"status": "ok", "environment": settings.app_env}


@app.get("/ready")
async def ready() -> dict:
    requests_total.labels(route="ready").inc()
    checks = {
        "database_configured": bool(
            settings.database_url or (settings.database_secret and settings.rds_host)
        ),
        "redis": (
            await check_redis(settings)
            if settings.redis_url or (settings.redis_auth_token and settings.redis_host)
            else "disabled"
        ),
        "dynamodb_configured": bool(settings.dynamodb_table_name),
        "s3_configured": bool(settings.s3_bucket_name),
        "sqs_configured": bool(settings.sqs_queue_url),
    }
    return {"status": "ready", "checks": checks}


@app.post("/api/v1/items", status_code=201)
async def items(item: ItemCreate) -> dict:
    requests_total.labels(route="items").inc()
    try:
        return await create_item(settings, item)
    except ServiceConfigurationError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@app.post("/api/v1/jobs", status_code=202)
async def jobs(job: JobCreate) -> dict:
    requests_total.labels(route="jobs").inc()
    try:
        result = submit_job(settings, job)
        logger.info("job_queued", extra={"job_id": result["job_id"]})
        return result
    except ServiceConfigurationError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@app.get("/api/v1/jobs/{job_id}")
async def job_status(job_id: uuid.UUID) -> dict:
    requests_total.labels(route="job_status").inc()
    try:
        result = get_job(settings, str(job_id))
        if result is None:
            raise HTTPException(status_code=404, detail="job not found")
        return result
    except ServiceConfigurationError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@app.post("/api/v1/uploads/presigned")
async def presigned_upload(request: UploadRequest) -> dict:
    requests_total.labels(route="upload").inc()
    try:
        return {
            "method": "PUT",
            "url": create_upload_url(settings, request.object_key, request.content_type),
            "expires_in": 900,
        }
    except ServiceConfigurationError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@app.get("/metrics")
async def metrics() -> Response:
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
