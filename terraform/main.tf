data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  src_bucket = "${var.project}-originales-${local.account_id}"
  dst_bucket = "${var.project}-miniaturas-${local.account_id}"
  web_bucket = "${var.project}-frontend-${local.account_id}"

  repo_url = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.project}-thumb"

  tags = {
    Project     = "parcial_ajlg"
    Environment = "parcial"
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Localiza la raíz del proyecto (carpeta que contiene frontend/, lambda/, container/)
# sin importar si los .tf están sueltos en la raíz, en terraform/ o en
# parcial_ajlg/terraform. Se puede forzar con -var="project_root=../mi_ruta".
# ---------------------------------------------------------------------------
locals {
  _root_candidates = [
    "${path.module}",
    "${path.module}/..",
    "${path.module}/../parcial_ajlg",
    "${path.module}/../..",
    "${path.module}/../../parcial_ajlg",
  ]

  _valid_roots = [
    for c in local._root_candidates : c
    if fileexists("${c}/frontend/index.html") && fileexists("${c}/lambda/trigger/handler.py")
  ]

  project_root = var.project_root != null ? var.project_root : (
    length(local._valid_roots) > 0 ? local._valid_roots[0] : "${path.module}/.."
  )
}

# Aviso claro si las carpetas del proyecto no están donde se espera
check "rutas_del_proyecto" {
  assert {
    condition = (
      fileexists("${local.project_root}/frontend/index.html") &&
      fileexists("${local.project_root}/lambda/trigger/handler.py") &&
      fileexists("${local.project_root}/container/Dockerfile")
    )
    error_message = "No encuentro frontend/, lambda/ o container/ desde '${local.project_root}'. Pasa la ruta correcta: terraform plan -var=\"project_root=../parcial_ajlg\""
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "a" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = var.az_a

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_subnet" "b" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = var.az_b

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}
