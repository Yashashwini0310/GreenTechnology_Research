#############################################
# ECS on EC2 (bridge mode) with ALB (HTTP80)
#############################################

# --- Security groups ---
resource "aws_security_group" "alb_sg_ecs" {
  name        = "${var.project}-alb-ec2-sg"
  description = "ALB ingress 80"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg_ecs" {
  name        = "${var.project}-ec2-container-sg"
  description = "EC2 container instance SG"
  vpc_id      = data.aws_vpc.default.id

  # Only ALB can reach host port 8080
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg_ecs.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- ALB + TG (instance targets because we're using bridge mode) ---
resource "aws_lb" "alb_ecs" {
  name               = "${var.project}-alb-ec2"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg_ecs.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "tg_ecs" {
  name        = "${var.project}-tg-ec2"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance" # <- bridge mode uses instance targets
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/"
    port                = 8080
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http_ecs" {
  load_balancer_arn = aws_lb.alb_ecs.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_ecs.arn
  }
}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "cluster_ec2" {
  name = "${var.project}-cluster-ec2"
}

# --- AMI for ECS-optimized Amazon Linux 2 ---
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# --- Launch Template for ECS container instance ---
# IMPORTANT: You must provide an *existing* IAM Instance Profile name that your lab allows.
# It should have permissions for ECR (read) and CloudWatch Logs (put).
resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "${var.project}-ecs-ec2-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.ecs_instance_type

  # attach SG that allows ALB->8080
  # vpc_security_group_ids = [aws_security_group.ec2_sg_ecs.id]
  network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg_ecs.id]
  }
  # Use an existing instance profile provided by your lab (e.g., one that includes LabRole)
  iam_instance_profile {
    name = var.ecs_instance_profile_name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=${var.project}-cluster-ec2" >> /etc/ecs/ecs.config
              systemctl enable --now ecs
              EOF
  )

  monitoring {
    enabled = true
  }
}

# --- AutoScaling group to provide 1 container host ---
resource "aws_autoscaling_group" "ecs_asg" {
  name_prefix         = "${var.project}-ecs-asg"
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 60

  lifecycle {
    create_before_destroy = true
  }
}

# --- CloudWatch Logs ---
resource "aws_cloudwatch_log_group" "logs_ec2" {
  name              = "/ecs/${var.project}-ec2"
  retention_in_days = 7
}

# --- ECR image URI ---
data "aws_caller_identity" "me" {}

locals {
  image_uri = "${data.aws_caller_identity.me.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_repo}:${var.image_tag}"
}

# --- Task Definition (bridge mode, hostPort 8080) ---
resource "aws_ecs_task_definition" "task_ec2" {
  family                   = "${var.project}-task-ec2"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = var.fargate_cpu # reuse sizing vars; not used strictly in EC2 mode
  memory                   = var.fargate_memory

  # No execution_role_arn needed for EC2 launch type; the *instance profile* provides creds.

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = local.image_uri
      essential = true
      portMappings = [{
        containerPort = 8080,
        hostPort      = 8080,
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.logs_ec2.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "app"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/ || exit 1"]
        interval    = 15
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}

# --- ECS Service (EC2 launch type) ---
resource "aws_ecs_service" "svc_ec2" {
  name            = "${var.project}-svc-ec2"
  cluster         = aws_ecs_cluster.cluster_ec2.id
  task_definition = aws_ecs_task_definition.task_ec2.arn
  desired_count   = 1
  launch_type     = "EC2"

  # ALB (instance targets)
  load_balancer {
    target_group_arn = aws_lb_target_group.tg_ecs.arn
    container_name   = "app"
    container_port   = 8080
  }

  depends_on = [
    aws_autoscaling_group.ecs_asg,
    aws_lb_listener.http_ecs
  ]
}
