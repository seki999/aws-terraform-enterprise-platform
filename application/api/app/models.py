from typing import Any

from pydantic import BaseModel, Field


class ItemCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)


class JobCreate(BaseModel):
    object_key: str = Field(min_length=1, max_length=1024)
    operation: str = Field(default="inspect", pattern="^(inspect|transform|archive)$")
    metadata: dict[str, Any] = Field(default_factory=dict)


class UploadRequest(BaseModel):
    object_key: str = Field(min_length=1, max_length=1024)
    content_type: str = Field(default="application/octet-stream", max_length=200)

