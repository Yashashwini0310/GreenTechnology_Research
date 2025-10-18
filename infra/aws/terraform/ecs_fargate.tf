# ===== Security groups (unique names for Fargate stack) =====
resource "aws_security_group" "alb_sg_fargate" {
  name        = "${var.project}-alb-sg"
  description = "ALB ingress 80"
  vpc_id      = data.aws_vpc.default.id

  ingress {
  from_port = 80
  to_port = 80
  protocol = "tcp" 
  cidr_blocks = ["0.0.0.0/0"]
  }
  egress  {
  from_port = 0   
  to_port = 0   
  protocol = "-1"  
  cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "svc_sg_fargate" {
  name        = "${var.project}-fargate-sg"
  description = "Fargate service SG"
  vpc_id      = data.aws_vpc.default.id

  # Only allow traffic from ALB to container port
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg_fargate.id]
  }
  egress { 
  from_port = 0 
  to_port = 0 
  protocol = "-1" 
  cidr_blocks = ["0.0.0.0/0"]
  }
}

# ===== ALB + target group + listener =====
resource "aws_lb" "alb" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg_fargate.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.project}-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
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

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ===== ECS cluster (can be shared) =====
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project}-cluster"
}

# ===== Use EXISTING task execution role (LabRole environments) =====
# Add in variables.tf: variable "task_execution_role_name" { default = "ecsTaskExecutionRole" }
data "aws_iam_role" "task_exec" {
  name = var.task_execution_role_name
}

# ===== CloudWatch Logs =====
resource "aws_cloudwatch_log_group" "logs" {
  name              = "/ecs/${var.project}"
  retention_in_days = 7
}

# ===== Image URI from your account/ECR =====
data "aws_caller_identity" "me" {}

locals {
  image_uri = "${data.aws_caller_identity.me.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_repo}:${var.image_tag}"
}

# ===== Task definition =====
resource "aws_ecs_task_definition" "task" {
  family                   = "${var.project}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory

  # Use existing execution role (no IAM creation in TF)
  execution_role_arn = data.aws_iam_role.task_exec.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = local.image_uri
      essential = true
      portMappings = [{ containerPort = 8080, hostPort = 8080, protocol = "tcp" }]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/ || exit 1"]
        interval    = 15
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.logs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])
}

# ===== Service =====
resource "aws_ecs_service" "svc" {
  name            = "${var.project}-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.svc_sg_fargate.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "app"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]
}
