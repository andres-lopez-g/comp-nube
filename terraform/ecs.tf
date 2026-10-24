# ---------------------------------------------------------------------------
# ECR + ECS Fargate (SIN service: el contenedor solo vive cuando la Lambda
# hace ecs:RunTask; no corre el 100% del tiempo)
# ---------------------------------------------------------------------------

resource "aws_ecr_repository" "thumb" {
  name = "${var.project}-thumb"

  image_scanning_configuration {
    scan_on_push = true
  }

  # permite terraform destroy aunque queden imágenes
  force_delete = true
}

resource "aws_ecs_cluster" "thumb" {
  name = "${var.lambda_prefix}_cluster"
}

resource "aws_cloudwatch_log_group" "thumb" {
  name              = "/ecs/${var.lambda_prefix}_thumb_task"
  retention_in_days = 7
}

resource "aws_security_group" "fargate" {
  name        = "${var.lambda_prefix}_fargate_sg"
  description = "parcial_ajlg - tareas Fargate (solo salida)"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_task_definition" "thumb" {
  family                   = "${var.lambda_prefix}_thumb_task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_exec.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "${var.lambda_prefix}_processor"
      image     = "${local.repo_url}:${var.image_tag}"
      essential = true

      environment = [
        { name = "DEST_BUCKET", value = aws_s3_bucket.miniaturas.id },
        { name = "THUMB_SIZE", value = var.thumb_size },
        { name = "DEST_PREFIX", value = var.thumb_prefix },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.thumb.name
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "parcial_ajlg"
        }
      }
    }
  ])
}
