# ---------------------------------------------------------------------------
# Frontend: se publica desde Terraform como sitio estático en S3
# Las rutas salen de local.project_root (autodetectado, ver main.tf)
# ---------------------------------------------------------------------------

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  source       = "${local.project_root}/frontend/index.html"
  etag         = filemd5("${local.project_root}/frontend/index.html")
  content_type = "text/html; charset=utf-8"

  depends_on = [aws_s3_bucket_policy.frontend]
}

resource "aws_s3_object" "styles" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "styles.css"
  source       = "${local.project_root}/frontend/styles.css"
  etag         = filemd5("${local.project_root}/frontend/styles.css")
  content_type = "text/css; charset=utf-8"

  depends_on = [aws_s3_bucket_policy.frontend]
}

resource "aws_s3_object" "app" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "app.js"
  source       = "${local.project_root}/frontend/app.js"
  etag         = filemd5("${local.project_root}/frontend/app.js")
  content_type = "application/javascript; charset=utf-8"

  depends_on = [aws_s3_bucket_policy.frontend]
}

# Los nombres de bucket se inyectan solos: no hay que editar nada a mano
resource "aws_s3_object" "config" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "config.js"
  content_type = "application/javascript; charset=utf-8"

  content = <<-EOT
    // parcial_ajlg — generado por Terraform (buckets públicos del parcial)
    window.PARCIAL_AJLG = {
      srcBucket: "${aws_s3_bucket.originales.id}",
      dstBucket: "${aws_s3_bucket.miniaturas.id}"
    };
  EOT

  # sin etag manual: Terraform detecta cambios de `content` solo
  depends_on = [aws_s3_bucket_policy.frontend]
}
