# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------

# Rol de ejecución de ECS (pull de ECR + logs)
resource "aws_iam_role" "ecs_exec" {
  name = "${var.lambda_prefix}_ecs_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec" {
  role       = aws_iam_role.ecs_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Rol de la tarea: leer originales y escribir miniaturas
resource "aws_iam_role" "ecs_task" {
  name = "${var.lambda_prefix}_ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ecs_task_s3" {
  name = "s3-thumbs"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:GetObjectAttributes", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.originales.arn,
          "${aws_s3_bucket.originales.arn}/*",
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.miniaturas.arn}/*"
      }
    ]
  })
}

# Rol de la Lambda que dispara el contenedor
resource "aws_iam_role" "lambda_trigger" {
  name = "${var.lambda_prefix}_lambda_trigger_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_trigger_logs" {
  role       = aws_iam_role.lambda_trigger.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_trigger_run" {
  name = "run-fargate"
  role = aws_iam_role.lambda_trigger.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecs:RunTask"]
        Resource = "${aws_ecs_task_definition.thumb.arn_without_revision}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["ecs:DescribeTasks"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [
          aws_iam_role.ecs_exec.arn,
          aws_iam_role.ecs_task.arn,
        ]
      }
    ]
  })
}
