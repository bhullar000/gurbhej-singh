# aws-deploy-template

Infrastructure-as-Code template for running **containerized, long-running jobs on AWS Batch** —
the exact pattern I use to deploy genomics and data pipelines to production.

> Public reference template. No client code — just the reusable DevOps scaffolding:
> **Docker → ECR → AWS Batch (custom AMI + launch template) → S3**.

## Architecture

```
                    ┌──────────────┐   docker push    ┌───────────────┐
   git push  ─────► │ GitHub Actions│ ───────────────► │  Amazon ECR   │
                    │  (OIDC → AWS) │                  │  image:latest │
                    └──────────────┘                  └───────┬───────┘
                                                              │ pull
  submit job    ┌───────────────┐   dispatch   ┌──────────────▼───────────────┐
  (Nextflow /  ─► genomics-job- ├────────────► │  AWS Batch Compute Environment│
   CLI)         │  queue        │              │  EC2 auto-scaling             │
               └───────────────┘              │  ├─ Custom AMI                │
                                              │  └─ Launch Template (gp3 200GB)│
                                              └──────────────┬───────────────┘
                                                             │ read / write
                                                     ┌───────▼───────┐
                                                     │   Amazon S3   │
                                                     │ inputs/results│
                                                     └───────────────┘
```

## What it provisions (Terraform)

| Resource | File | Purpose |
| --- | --- | --- |
| ECR repository + lifecycle policy | `infra/ecr.tf` | Stores versioned container images, scan-on-push |
| IAM roles (instance / service / job) | `infra/iam.tf` | Least-privilege access for nodes, Batch, and S3 |
| Launch template + custom AMI | `infra/batch.tf` | Compute nodes with baked tooling + 200 GB scratch |
| Batch compute environment | `infra/batch.tf` | Auto-scaling EC2 (0 → `max_vcpus`) |
| Batch **job queue** (`genomics-job-queue`) | `infra/batch.tf` | Target for Nextflow / `aws batch submit-job` |
| Batch job definition | `infra/batch.tf` | Pulls image from ECR, mounts job role |

## Deploy

```bash
cd infra
terraform init
terraform apply -var="project=genomics" -var="custom_ami_id=ami-xxxxxxxx"
# outputs: ecr_repository_url, batch_job_queue, launch_template_id
```

## Build & push the image

Locally:
```bash
docker compose build
aws ecr get-login-password | docker login --username AWS --password-stdin <acct>.dkr.ecr.us-east-1.amazonaws.com
docker tag genomics-pipeline:local <ecr_repository_url>:latest
docker push <ecr_repository_url>:latest
```

Or automatically on every push to `main` via [`.github/workflows/deploy-ecr.yml`](.github/workflows/deploy-ecr.yml)
(uses GitHub OIDC — **no long-lived AWS keys**).

## Run a job

```bash
# via Nextflow (see nextflow-genomics-demo)
nextflow run main.nf -profile awsbatch

# or directly
aws batch submit-job \
  --job-name demo \
  --job-queue genomics-job-queue \
  --job-definition genomics-pipeline-job
```

## Skills demonstrated

`Terraform` · `AWS Batch` · `Custom AMI + Launch Template` · `Amazon ECR` · `IAM least-privilege` ·
`GitHub Actions (OIDC)` · `Docker` · `S3 data staging`

---
Built by **Gurbhej Singh** — [Portfolio](https://gurbhejsingh.dev) · [Upwork (Top Rated)](https://www.upwork.com/)
