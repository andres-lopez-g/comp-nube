output "frontend_url" {
  description = "URL del sitio estático (abrir esta en el navegador)"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "src_bucket" {
  description = "Bucket de originales (público: PUT/GET en uploads/)"
  value       = aws_s3_bucket.originales.id
}

output "dst_bucket" {
  description = "Bucket de miniaturas (público: GET en thumbs/)"
  value       = aws_s3_bucket.miniaturas.id
}

output "repo_url" {
  description = "URI del repo ECR para docker push"
  value       = aws_ecr_repository.thumb.repository_url
}

output "cluster_name" {
  value = aws_ecs_cluster.thumb.name
}

output "lambda_trigger" {
  value = aws_lambda_function.trigger.function_name
}

output "build_push_cmd" {
  description = "Comando para construir y subir la imagen"
  value       = "bash scripts/build_push.sh"
}
