#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_DIR="${ROOT_DIR}/infra/terraform/env/dev"
APP_DIR="${ROOT_DIR}/backend/tasktracker"
AWS_REGION="us-east-2"
IMAGE_TAG="${1:-dev}"
LOCAL_IMAGE="tasktracker-dev-backend:${IMAGE_TAG}"

cd "${ENV_DIR}"

REPO_URL="$(terraform output -raw backend_ecr_repository_url)"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

aws ecr get-login-password --region "${AWS_REGION}" | \
docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

cd "${APP_DIR}"

docker buildx build \
  --platform linux/amd64 \
  -t "${LOCAL_IMAGE}" \
  . \
  --load

docker tag "${LOCAL_IMAGE}" "${REPO_URL}:${IMAGE_TAG}"

docker push "${REPO_URL}:${IMAGE_TAG}"

echo "Pushed image:"
echo "${REPO_URL}:${IMAGE_TAG}"