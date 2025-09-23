terraform {
    required_version = ">= 1.6.0"
    required_providers {
        aws = { source = "hashicorp/aws", version = ">= 5.0" }
    }
}
provider "aws" {
    region = var.region
}


# Modules split across files: ec2.tf, ecs_fargate.tf, lambda.tf, networking.tf