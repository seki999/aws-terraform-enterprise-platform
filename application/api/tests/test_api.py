from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)


def test_health() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_job_validation_rejects_empty_object_key() -> None:
    response = client.post("/api/v1/jobs", json={"object_key": "", "operation": "inspect"})
    assert response.status_code == 422


def test_job_returns_503_without_queue_configuration() -> None:
    response = client.post("/api/v1/jobs", json={"object_key": "input/file.txt"})
    assert response.status_code == 503


def test_metrics() -> None:
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "platform_api_requests_total" in response.text

