# nextflow-genomics-demo

A minimal, **nf-core-style** Nextflow (DSL2) pipeline that demonstrates how I build
**reproducible, containerized bioinformatics workflows** that scale from a laptop to
**AWS Batch** for long-running production jobs.

> This is a public demo built on the open-source Nextflow / nf-core ecosystem — no client
> code or data. It mirrors the patterns I use on real genomics engagements.

## What it does

```
samplesheet.csv ──► FASTQC (per sample) ──► MULTIQC (aggregated report)
```

- Reads an nf-core-style **samplesheet** (`sample,fastq`)
- Runs **FastQC** on each sample in parallel, each in its own container
- Aggregates results into a single **MultiQC** report
- Emits timeline / trace / resource reports for every run

## Run it locally (Docker)

```bash
nextflow run main.nf -profile docker
# results/ → fastqc/, multiqc/, pipeline_info/
```

## Run it at scale on AWS Batch

The `awsbatch` profile submits each process as an AWS Batch job. The compute environment
(**custom AMI + launch template + job queue**, with container images in **ECR**) is
provisioned by my companion [aws-deploy-template](https://github.com/gurbhej-singh/aws-deploy-template) repo.

```bash
nextflow run main.nf \
  -profile awsbatch \
  --input  s3://my-genomics-bucket/samplesheet.csv \
  --outdir s3://my-genomics-bucket/results
```

```nextflow
// nextflow.config (awsbatch profile)
process.executor = 'awsbatch'
process.queue    = 'genomics-job-queue'
aws.region       = 'us-east-1'
workDir          = 's3://my-genomics-bucket/nextflow-work'
```

## Why this matters for production genomics

| Concern | How the pipeline handles it |
| --- | --- |
| **Reproducibility** | Pinned container images per process; versioned pipeline manifest |
| **Scale** | Same code runs one sample locally or thousands of jobs on AWS Batch |
| **Long-running jobs** | AWS Batch queues + auto-scaling EC2 from a launch template |
| **Cost & runtime visibility** | Built-in timeline / trace / resource reports |
| **Portability** | Docker & Singularity profiles for HPC or cloud |

## Project structure

```
main.nf                     # workflow entrypoint
nextflow.config             # params, resource labels, docker/awsbatch profiles
modules/local/fastqc.nf     # FastQC process
modules/local/multiqc.nf    # MultiQC aggregation
assets/samplesheet.csv      # example input (public nf-core test data)
```

## Skills demonstrated

`Nextflow DSL2` · `nf-core conventions` · `Docker / Singularity` · `AWS Batch` ·
`S3 work dirs` · `containerized bioinformatics` · `resource & cost profiling`

---
Built by **Gurbhej Singh** — [Portfolio](https://gurbhejsingh.dev) · [Upwork (Top Rated)](https://www.upwork.com/)
