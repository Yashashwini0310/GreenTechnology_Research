variable "region" {
  type    = string
  default = "us-east-1"
}
variable "project" {
  type    = string
  default = "sust-compute-study"

}
variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"

}

# Optional for later (containers/serverless)

variable "fargate_cpu" {
  type    = string
  default = "1024"

} # 1 vCPU
variable "fargate_memory" {
  type    = string
  default = "2048"

} # 2 GB
variable "lambda_memory" {
  type    = number
  default = 512

}

# SSH (use only if you want SSH access)
variable "ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"

} # open - OK for short lab
# variable "key_name"           { type = string }                         # your EC2 key pair name

# Repo info used by user_data in main.tf
variable "github_owner" {
  type = string

} # e.g., "your-github-username"
variable "github_repo" {
  type    = string
  default = "sustainability-compute-study"

}
# Instance type for the ECS container host
variable "ecs_instance_type" {
  type    = string
  default = "t3.micro"
}

# variables.tf
variable "ecs_instance_profile_name" {
  type        = string
  description = "LabRole existing"
  default     = "LabRole"
}

variable "ecr_repo" {
  default = "sust-microservice"
}

variable "image_tag" {
  default = "v1"
}