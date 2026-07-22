from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """运行时配置只从环境读取，避免把凭证写入代码或镜像。"""

    app_env: str = "local"
    log_level: str = "INFO"
    aws_region: str = "ap-northeast-1"
    aws_endpoint_url: str | None = None
    database_url: str | None = None
    database_secret: str | None = None
    database_name: str = "platform"
    rds_host: str | None = None
    redis_url: str | None = None
    redis_auth_token: str | None = None
    redis_host: str | None = None
    dynamodb_table_name: str | None = None
    s3_bucket_name: str | None = None
    sqs_queue_url: str | None = None

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
