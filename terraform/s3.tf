# ---------------------------------------------------------------------------
# S3: originales (público para PUT/GET/List de uploads/*)
#     miniaturas (público para GET/List de thumbs/*)
#     Los buckets son públicos solo porque es un parcial: la web estática
#     sube directo sin backend ni Cognito.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "originales" {
  bucket = local.src_bucket

  # permite terraform destroy sin vaciar a mano
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "originales" {
  bucket = aws_s3_bucket.originales.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_cors_configuration" "originales" {
  bucket = aws_s3_bucket.originales.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 300
  }
}

resource "aws_s3_bucket_policy" "originales" {
  bucket = aws_s3_bucket.originales.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicPutUploads"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.originales.arn}/${var.upload_prefix}*"
      },
      {
        Sid       = "PublicReadUploads"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.originales.arn}/${var.upload_prefix}*"
      },
      {
        Sid       = "PublicListUploads"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.originales.arn
        Condition = {
          StringLike = { "s3:prefix" = "${var.upload_prefix}*" }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.originales]
}

resource "aws_s3_bucket" "miniaturas" {
  bucket        = local.dst_bucket
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "miniaturas" {
  bucket = aws_s3_bucket.miniaturas.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_cors_configuration" "miniaturas" {
  bucket = aws_s3_bucket.miniaturas.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 300
  }
}

resource "aws_s3_bucket_policy" "miniaturas" {
  bucket = aws_s3_bucket.miniaturas.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadThumbs"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.miniaturas.arn}/${var.thumb_prefix}*"
      },
      {
        Sid       = "PublicListThumbs"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.miniaturas.arn
        Condition = {
          StringLike = { "s3:prefix" = "${var.thumb_prefix}*" }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.miniaturas]
}

# ---------------------------------------------------------------------------
# S3: frontend estático
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "frontend" {
  bucket        = local.web_bucket
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicRead"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}
