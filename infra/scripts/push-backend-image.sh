#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_DIR="${ROOT_DIR}/infra/terraform/env/dev"
BOOTSTRAP_DIR="${ROOT_DIR}/infra/terraform/bootstrap/state"
APP_DIR="${ROOT_DIR}/backend/tasktracker"
CF_DIR="${ROOT_DIR}/infra/cloudformation"

AWS_REGION="us-east-2"
IMAGE_TAG="${1:-dev}"
LOCAL_IMAGE="tasktracker-dev-backend:${IMAGE_TAG}"

cd "${BOOTSTRAP_DIR}"

ARTIFACT_BUCKET="$(terraform output -raw cfn_artifacts_bucket)"

cd "${ENV_DIR}"

REPO_URL="$(terraform output -raw backend_ecr_repository_url)"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

echo "========================================"
echo "Logging into Amazon ECR"
echo "========================================"

aws ecr get-login-password --region "${AWS_REGION}" | \
docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "========================================"
echo "Building backend Docker image"
echo "========================================"

cd "${APP_DIR}"

docker buildx build \
  --platform linux/amd64 \
  -t "${LOCAL_IMAGE}" \
  . \
  --load

echo "========================================"
echo "Tagging Docker image"
echo "========================================"

docker tag "${LOCAL_IMAGE}" "${REPO_URL}:${IMAGE_TAG}"

echo "========================================"
echo "Pushing Docker image to ECR"
echo "========================================"

docker push "${REPO_URL}:${IMAGE_TAG}"

echo "========================================"
echo "Publishing CloudFormation artifacts"
echo "========================================"

cd "${CF_DIR}"

aws s3 cp \
  components/ecs-fargate/service.yml \
  "s3://${ARTIFACT_BUCKET}/tasktracker-dev/components/ecs-fargate/service.yml"

aws s3 cp \
  stacks/ecs-fargate/skeleton.yml \
  "s3://${ARTIFACT_BUCKET}/tasktracker-dev/stacks/ecs-fargate/skeleton.yml"

echo "========================================"
echo "Deployment artifacts published"
echo "========================================"

echo
echo "Docker image:"
echo "${REPO_URL}:${IMAGE_TAG}"

echo
echo "CloudFormation artifact bucket:"
echo "${ARTIFACT_BUCKET}"