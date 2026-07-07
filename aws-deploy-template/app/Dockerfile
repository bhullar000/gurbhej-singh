# Container image that Batch jobs run. Build → push to ECR via CI.
FROM python:3.12-slim AS base

# AWS CLI is used inside jobs to stage data to/from S3
RUN apt-get update && apt-get install -y --no-install-recommends \
        awscli procps ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENTRYPOINT ["python", "run.py"]
