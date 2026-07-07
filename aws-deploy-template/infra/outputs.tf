output "ecr_repository_url" {
  description = "Push container images here (used by CI and Batch job definition)"
  value       = aws_ecr_repository.app.repository_url
}

output "batch_job_queue" {
  description = "Job queue name for Nextflow (process.queue) or aws batch submit-job"
  value       = aws_batch_job_queue.this.name
}

output "compute_environment" {
  value = aws_batch_compute_environment.this.compute_environment_name
}

output "launch_template_id" {
  value = aws_launch_template.batch.id
}
