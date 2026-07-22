FROM python:3.13-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 HEALTHCHECK_FILE=/var/run/worker/heartbeat
RUN groupadd --system worker \
  && useradd --system --gid worker --create-home worker \
  && install -d --owner=worker --group=worker /var/run/worker
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY worker.py .
USER worker
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["python", "-c", "import os,sys,time; p=os.environ['HEALTHCHECK_FILE']; sys.exit(0 if os.path.isfile(p) and time.time()-os.path.getmtime(p)<90 else 1)"]
CMD ["python", "worker.py"]
