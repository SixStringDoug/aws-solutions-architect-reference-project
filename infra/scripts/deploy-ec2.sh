#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${ROOT_DIR}/backend/tasktracker"
ARTIFACT_DIR="${ROOT_DIR}/artifacts"
BOOTSTRAP_DIR="${ROOT_DIR}/infra/terraform/bootstrap/state"
ENV_DIR="${ROOT_DIR}/infra/terraform/env/dev"
TFVARS_FILE="test-ec2.tfvars"

ACTION="${1:-full-validate}"

echo "========================================"
echo "TaskTracker EC2 Deployment Helper"
echo "Action: ${ACTION}"
echo "========================================"

build_artifact() {
echo "Building backend JAR..."
cd "${APP_DIR}"
./mvnw clean package -DskipTests

echo "Copying backend JAR to artifacts..."
mkdir -p "${ARTIFACT_DIR}"
cp target/*.jar "${ARTIFACT_DIR}/tasktracker.jar"
}

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

env_validate() {
build_artifact
validate_env
}

env_deploy() {
build_artifact
validate_env

echo "Deploying EC2 infrastructure..."
cd "${ENV_DIR}"
terraform apply -auto-approve -var-file="${TFVARS_FILE}"

echo "EC2 ALB DNS name:"
terraform output ec2_alb_dns_name
}

env_destroy() {
echo "Destroying EC2 infrastructure..."
cd "${ENV_DIR}"
terraform init -reconfigure
terraform destroy -auto-approve -var-file="${TFVARS_FILE}"
}

case "${ACTION}" in
bootstrap-deploy)
bootstrap_deploy
;;

bootstrap-destroy)
bootstrap_destroy
;;

env-validate)
env_validate
;;

env-deploy)
env_deploy
;;

env-destroy)
env_destroy
;;

full-validate)
echo "Running full EC2 validation..."
bootstrap_deploy
env_validate
;;

full-deploy)
echo "Running full EC2 deployment..."
bootstrap_deploy
env_deploy
;;

full-destroy)
echo "Running full EC2 destroy..."
env_destroy
bootstrap_destroy
;;

*)
echo "Usage: $0 [bootstrap-deploy|bootstrap-destroy|env-validate|env-deploy|env-destroy|full-validate|full-deploy|full-destroy]"
exit 1
;;
esac

echo "Done."
