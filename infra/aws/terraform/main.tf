# terraform {
#     required_version = ">= 1.6.0"
#     required_providers {
#         aws = { source = "hashicorp/aws", version = ">= 5.0" }
#     }
# }
# provider "aws" {
#     region = var.region
# }


# # Modules split across files: ec2.tf, ecs_fargate.tf, lambda.tf, networking.tf

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    version = ">= 5.0" }
  }
}

provider "aws" {
  region = var.region
  # In AWS Academy Cloud9, credentials are provided via LabRole automatically.
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "svc_sg" {
  name        = "${var.project}-sg"
  description = "Allow SSH and app port"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr] # set to your IP/CIDR
  }

  ingress {
    description = "App"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # open for testing; tighten later
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  # Only pick AZs where your instance type is supported.
  # us-east-1e is excluded on purpose.
  filter {
    name = "availability-zone"
    values = [
      "${var.region}a",
      "${var.region}b",
      "${var.region}c",
      "${var.region}d",
      "${var.region}f"
    ]
  }
}

resource "aws_instance" "vm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.svc_sg.id]
  associate_public_ip_address = true
  #   key_name                    = var.key_name   # create/import in EC2 → Key Pairs

  user_data = <<-EOF
              #!/bin/bash
              set -eux pipefail
              apt-get update -y
              apt-get install -y python3-venv python3-pip git curl
              # cd /opt
              if [ ! -d /opt/GreenTechnology_Research ]; then
              git clone https://github.com/Yashashwini0310/GreenTechnology_Research.git /opt/GreenTechnology_Research
              fi
            
              cd /opt/GreenTechnology_Research
              
              python3 -m venv .venv
              . .venv/bin/activate
              python3 -m pip install --upgrade pip
              [ -f requirements.txt ] && pip install -r requirements.txt || true
              [ -f services/app/requirements.txt ] && pip install -r services/app/requirements.txt || true
              # install deps
              # run with 4 workers (no reload) and listen on 0.0.0.0:8000
              nohup .venv/bin/uvicorn services.app.main:app \
              --host 0.0.0.0 --port 8080 --workers 4 \
              > /tmp/uvicorn.out 2>&1 &
              
              # small health check so you can see 200 OK in the instance system log
              sleep 5
              curl -I http://127.0.0.1:8080/docs || true
              EOF

  tags = {
    Name = "${var.project}-ec2"
  }
}

# output "public_ip" {
#   value = aws_instance.vm.public_ip
# }

# output "app_url" {
#   value = "http://${aws_instance.vm.public_ip}:8000/docs"
# }
