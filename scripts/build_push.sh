#!/usr/bin/env bash
# parcial_ajlg — construye y sube la imagen del contenedor a ECR.
# Uso: bash scripts/build_push.sh   (desde cualquier carpeta)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

# --- localizar la raíz del proyecto (la que tiene container/Dockerfile) ---
ROOT=""
for c in "$HERE/.." "$HERE/../parcial_ajlg" "$HERE/../.." "$HERE/../../parcial_ajlg"; do
  if [ -f "$c/container/Dockerfile" ]; then ROOT="$(cd "$c" && pwd)"; break; fi
done
if [ -z "$ROOT" ]; then
  echo "ERROR: no encuentro container/Dockerfile. Ejecuta este script desde la carpeta del proyecto." >&2
  exit 1
fi

# --- localizar la carpeta de terraform ---
TF=""
for c in "$ROOT/terraform" "$HERE" "$HERE/.."; do
  if [ -f "$c/versions.tf" ]; then TF="$(cd "$c" && pwd)"; break; fi
done
if [ -z "$TF" ]; then
  echo "ERROR: no encuentro terraform (versions.tf)." >&2
  exit 1
fi

REGION="${REGION:-us-east-1}"
TAG="${TAG:-latest}"

echo "proyecto : $ROOT"
echo "terraform: $TF"

REPO_URL="$(terraform -chdir="$TF" output -raw repo_url)"
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"

echo "== ECR login =="
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"

echo "== docker build =="
docker build -t parcial-ajlg-thumb:"$TAG" "$ROOT/container"

echo "== docker push -> ${REPO_URL}:${TAG} =="
docker tag parcial-ajlg-thumb:"$TAG" "${REPO_URL}:${TAG}"
docker push "${REPO_URL}:${TAG}"

echo "LISTO. La task definition apunta a ${REPO_URL}:${TAG}"
echo "Sube una imagen desde el frontend para probar."
