#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOTSTRAP_DIR="${ROOT_DIR}/infra/terraform/bootstrap/state"
ENV_DIR="${ROOT_DIR}/infra/terraform/env/dev"
PUSH_IMAGE_SCRIPT="${ROOT_DIR}/infra/scripts/push-backend-image.sh"

TFVARS_FILE="test-fargate.tfvars"
TFVARS_PATH="${ENV_DIR}/${TFVARS_FILE}"

IMAGE_TAG="${2:-ph4}"
ACTION="${1:-full-validate}"

echo "========================================"
echo "TaskTracker Fargate Deployment Helper"
echo "Action: ${ACTION}"
echo "Image tag: ${IMAGE_TAG}"
echo "========================================"

validate_env() {
  echo "Running Terraform checks..."
  cd "${ENV_DIR}"
  terraform init -reconfigure
  terraform fmt -recursive
  terraform validate
}

bootstrap_deploy() {
  echo "Bootstrapping Terraform remote state..."
  cd "${BOOTSTRAP_DIR}"
  terraform init
  terraform apply -auto-approve
}

bootstrap_destroy() {
  echo "Destroying Terraform bootstrap resources..."
  cd "${BOOTSTRAP_DIR}"
  terraform destroy -auto-approve
}

set_cloudformation_false() {
  echo "Setting enable_cloudformation = false..."
  sed -i.bak 's/^enable_cloudformation *= *.*/enable_cloudformation = false/' "${TFVARS_PATH}"
  rm -f "${TFVARS_PATH}.bak"
}

set_cloudformation_true() {
  echo "Setting enable_cloudformation = true..."
  sed -i.bak 's/^enable_cloudformation *= *.*/enable_cloudformation = true/' "${TFVARS_PATH}"
  rm -f "${TFVARS_PATH}.bak"
}

base_deploy() {
  set_cloudformation_false
  validate_env

  echo "Deploying Fargate base infrastructure..."
  cd "${ENV_DIR}"
  terraform apply -auto-approve -var-file="${TFVARS_FILE}"
}

publish_image_and_artifacts() {
  echo "Publishing backend image and CloudFormation artifacts..."
  "${PUSH_IMAGE_SCRIPT}" "${IMAGE_TAG}"
}

service_deploy() {
  set_cloudformation_true
  validate_env

  echo "Deploying ECS service..."
  cd "${ENV_DIR}"
  terraform apply -auto-approve -var-file="${TFVARS_FILE}"

  echo "Fargate ALB DNS name:"
  terraform output fargate_alb_dns_name
}

service_destroy() {
  set_cloudformation_false

  echo "Destroying ECS service layer..."
  cd "${ENV_DIR}"
  terraform init -reconfigure
  terraform destroy -auto-approve -var-file="${TFVARS_FILE}"
}

base_destroy() {
  echo "Destroying Terraform bootstrap resources..."
  cd "${BOOTSTRAP_DIR}"
  terraform destroy -auto-approve
}

case "${ACTION}" in
  bootstrap-deploy)
    bootstrap_deploy
    ;;

  bootstrap-destroy)
    bootstrap_destroy
    ;;

  env-validate)
    validate_env
    ;;

  base-deploy)
    base_deploy
    ;;

  publish)
    publish_image_and_artifacts
    ;;

  service-deploy)
    service_deploy
    ;;

  service-destroy)
    service_destroy
    ;;

  base-destroy)
    base_destroy
    ;;

  full-validate)
    echo "Running full Fargate validation..."
    bootstrap_deploy
    validate_env
    ;;

  full-deploy)
    echo "Running full Fargate deployment..."
    bootstrap_deploy
    base_deploy
    publish_image_and_artifacts
    service_deploy
    ;;

  full-destroy)
    echo "Running full Fargate destroy..."
    service_destroy
    bootstrap_destroy
    ;;

  *)
    echo "Usage: $0 [bootstrap-deploy|bootstrap-destroy|env-validate|base-deploy|publish|service-deploy|service-destroy|base-destroy|full-validate|full-deploy|full-destroy] [image-tag]"
    exit 1
    ;;
esac

echo "Done."