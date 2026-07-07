# Resolve a default compute AMI if no custom AMI is supplied.
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

locals {
  compute_ami = var.custom_ami_id != "" ? var.custom_ami_id : jsondecode(data.aws_ssm_parameter.ecs_ami.value).image_id
}

resource "aws_security_group" "batch" {
  name        = "${var.project}-batch-sg"
  description = "AWS Batch compute nodes"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Launch template: bakes in the custom AMI + a larger scratch EBS volume ---
resource "aws_launch_template" "batch" {
  name = "${var.project}-batch-lt"

  image_id = local.compute_ami

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 200 # scratch space for large genomics intermediates
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Project = var.project, ManagedBy = "batch" }
  }
}

# --- Managed compute environment (auto-scaling EC2) ---
resource "aws_batch_compute_environment" "this" {
  compute_environment_name = "${var.project}-compute-env"
  type                     = "MANAGED"
  service_role             = aws_iam_role.batch_service_role.arn

  compute_resources {
    type                = "EC2"
    allocation_strategy = "BEST_FIT_PROGRESSIVE"
    min_vcpus           = 0
    desired_vcpus       = 0
    max_vcpus           = var.max_vcpus
    instance_type       = var.instance_types
    subnets             = data.aws_subnets.default.ids
    security_group_ids  = [aws_security_group.batch.id]
    instance_role       = aws_iam_instance_profile.ecs_instance_profile.arn

    launch_template {
      launch_template_id = aws_launch_template.batch.id
      version            = "$Latest"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.batch_service]
}

# --- Job queue that Nextflow (or any submitter) targets ---
resource "aws_batch_job_queue" "this" {
  name     = "genomics-job-queue"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.this.arn
  }
}

# --- Example job definition pulling the image from ECR ---
resource "aws_batch_job_definition" "pipeline" {
  name = "${var.project}-pipeline-job"
  type = "container"

  container_properties = jsonencode({
    image      = "${aws_ecr_repository.app.repository_url}:latest"
    jobRoleArn = aws_iam_role.job_role.arn
    vcpus      = 2
    memory     = 4096
    command    = ["run", "--input", "s3://my-genomics-bucket/samplesheet.csv"]
  })
}
