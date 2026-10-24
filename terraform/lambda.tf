# ---------------------------------------------------------------------------
# Lambda trigger: evento S3 -> ecs:RunTask (contenedor on-demand)
# ---------------------------------------------------------------------------

data "archive_file" "trigger" {
  type        = "zip"
  source_file = "${local.project_root}/lambda/trigger/handler.py"
  output_path = "${path.module}/build/trigger.zip"
}

resource "aws_lambda_function" "trigger" {
  function_name    = "${var.lambda_prefix}_trigger"
  role             = aws_iam_role.lambda_trigger.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  timeout          = 60
  memory_size      = 256
  filename         = data.archive_file.trigger.output_path
  source_code_hash = data.archive_file.trigger.output_base64sha256

  environment {
    variables = {
      PARCIAL_AJLG_CLUSTER   = aws_ecs_cluster.thumb.name
      PARCIAL_AJLG_TASKDEF   = aws_ecs_task_definition.thumb.family
      PARCIAL_AJLG_DEST_BUCKET = aws_s3_bucket.miniaturas.id
      PARCIAL_AJLG_SUBNETS   = "${data.aws_subnet.a.id},${data.aws_subnet.b.id}"
      PARCIAL_AJLG_SG        = aws_security_group.fargate.id
      PARCIAL_AJLG_CONTAINER = "${var.lambda_prefix}_processor"
      THUMB_SIZE             = var.thumb_size
      DEST_PREFIX            = var.thumb_prefix
    }
  }

  depends_on = [aws_cloudwatch_log_group.thumb]
}

# S3 necesita permiso explícito para invocar la función
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "parcial-ajlg-s3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.originales.arn
}

# Dispara SOLO cuando suben algo bajo uploads/ (no hay loop con miniaturas)
resource "aws_s3_bucket_notification" "originales" {
  bucket = aws_s3_bucket.originales.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.trigger.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.upload_prefix
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
