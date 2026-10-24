variable "region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefijo de recursos con guion (S3/ECR no aceptan guion bajo)"
  type        = string
  default     = "parcial-ajlg"
}

variable "lambda_prefix" {
  description = "Prefijo con guion bajo para Lambdas, cluster, roles y SG"
  type        = string
  default     = "parcial_ajlg"
}

variable "thumb_size" {
  description = "Lado mayor de la miniatura en píxeles"
  type        = string
  default     = "200"
}

variable "az_a" {
  description = "Zona de disponibilidad 1 (subnet pública default)"
  type        = string
  default     = "us-east-1a"
}

variable "az_b" {
  description = "Zona de disponibilidad 2 (subnet pública default)"
  type        = string
  default     = "us-east-1b"
}

variable "image_tag" {
  description = "Tag de la imagen en ECR"
  type        = string
  default     = "latest"
}

variable "project_root" {
  description = "Opcional: ruta a la carpeta que contiene frontend/, lambda/ y container/. Si se omite se autodetecta."
  type        = string
  default     = null
}

variable "upload_prefix" {
  description = "Prefijo donde caen los originales (dispara la Lambda)"
  type        = string
  default     = "uploads/"
}

variable "thumb_prefix" {
  description = "Prefijo donde el contenedor deja las miniaturas"
  type        = string
  default     = "thumbs/"
}
