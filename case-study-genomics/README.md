# Case Study — Genomics Data Processing Pipeline on AWS Batch

> A production engineering write-up. No client code or data — it documents the
> architecture, decisions, and outcomes of a real genomics pipeline I built.
> Companion demos: [nextflow-genomics-demo](https://github.com/gurbhej-singh/nextflow-genomics-demo) ·
> [aws-deploy-template](https://github.com/gurbhej-singh/aws-deploy-template)

---

## The problem

A team needed to process large volumes of sequencing data. Their existing setup ran on a
single powerful server and had three recurring pain points:

- **Not reproducible** — results varied with tool versions and manual steps.
- **Didn't scale** — a backlog of samples ran sequentially; jobs took many hours.
- **Fragile & costly** — a crashed run wasted a whole day, and the always-on server was
  paid for 24/7 even when idle.

## Goals

1. Reproducible runs anyone on the team can trigger and trust.
2. Parallelize across many samples and scale elastically.
3. Handle long-running jobs safely with retries and full cost/runtime visibility.
4. Pay only for compute actually used.

## The solution

I rebuilt the workflow with **Nextflow**, customizing **nf-core** conventions, and deployed it
to **AWS Batch** so jobs scale out across auto-scaling EC2 and pay-per-use compute.

```
 samplesheet ─► Nextflow (nf-core) ─► AWS Batch job queue ─► EC2 (custom AMI, launch template)
                                                                   │  pulls image
                                                            Amazon ECR (containers)
                                                                   │
                                                  Amazon S3 (inputs ─► results)
```

### Key decisions

| Decision | Why |
| --- | --- |
| **Nextflow + nf-core** | Battle-tested, resumable, community conventions; portable local ↔ cloud |
| **One container per process (ECR)** | Pinned tool versions → reproducibility; immutable, scanned images |
| **AWS Batch job queue** | Managed scheduling + auto-scaling for hours-long jobs; no idle servers |
| **Custom AMI + launch template** | Pre-baked tooling and large gp3 scratch volumes → faster starts, room for big intermediates |
| **S3 work dir** | Durable staging of inputs/intermediates/results; decouples storage from compute |
| **`-resume` + retries** | A failed step restarts from the last cached step, not from zero |

### Pipeline stages

`Quality Control → Read Alignment → Variant Calling → Annotation → Reporting`

Each stage is an isolated, containerized process. Nextflow builds the dependency graph and
runs independent samples/stages in parallel across the Batch compute environment.

## Outcomes

- ⏱️ **Long jobs parallelized** — sample backlog processed concurrently instead of one-by-one.
- 🔁 **Reproducible** — pinned containers + versioned pipeline; identical results across runs.
- 💰 **Lower cost** — compute scales to zero when idle; no always-on server.
- 🛡️ **Resilient** — failed steps resume from cache; retries handle spot/transient failures.
- 👀 **Visibility** — every run emits timeline, trace, and resource reports for cost/runtime review.

## Tech

`Nextflow` · `nf-core` · `Docker` · `AWS Batch` · `Amazon ECR` · `Custom AMI` ·
`Launch Templates` · `Amazon S3` · `Terraform` · `GitHub Actions`

## What I owned

- Pipeline architecture & nf-core customization
- Containerization of bioinformatics tools
- AWS infrastructure (Batch, ECR, custom AMI, launch template, IAM, S3)
- CI/CD for image builds and deployments
- Cost, runtime, and reliability tuning

---
Built by **Gurbhej Singh** — [Portfolio](https://gurbhejsingh.dev) · [Upwork (Top Rated)](https://www.upwork.com/)
