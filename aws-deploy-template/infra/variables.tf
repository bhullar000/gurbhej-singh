variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used to prefix resources"
  type        = string
  default     = "genomics"
}

variable "custom_ami_id" {
  description = "Custom AMI baked for compute nodes (Docker + AWS CLI + mounted scratch)"
  type        = string
  # e.g. built with Packer/EC2 Image Builder; leave empty to use the ECS-optimized AMI.
  default     = ""
}

variable "instance_types" {
  description = "EC2 instance types AWS Batch may launch"
  type        = list(string)
  default     = ["c5.large", "c5.xlarge", "m5.xlarge"]
}

variable "max_vcpus" {
  description = "Ceiling for the Batch compute environment"
  type        = number
  default     = 256
}
