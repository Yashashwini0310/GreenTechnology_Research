variable "region" { type = string, default = "eu-west-1" }
variable "ec2_instance_type" { type = string, default = "t3.medium" }
variable "fargate_cpu" { type = string, default = "1024" } # 1 vCPU
variable "fargate_memory" { type = string, default = "2048" } # 2 GB
variable "lambda_memory" { type = number, default = 512 }