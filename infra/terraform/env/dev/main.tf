module "attachments_bucket" {
  source      = "../../modules/s3_attachments"
  bucket_name = "${var.name_prefix}-attachments"
}

module "app_config" {
  source      = "../../modules/app_config"
  name_prefix = var.name_prefix
  environment = var.environment

  db_host = module.rds.endpoint
  db_port = module.rds.port

  db_username = var.db_username
  db_password = var.db_password
}

module "rds" {
  source      = "../../modules/rds_postgres"
  name_prefix = var.name_prefix
  environment = var.environment

  db_username = var.db_username
  db_password = var.db_password

  db_name = "tasktrackerdevpostgres"

  # Cost toggles (default cheap)
  multi_az                    = false
  use_managed_master_password = false

  # Safe default: deny connections unless you set a real CIDR
  allowed_cidr = "0.0.0.0/0"
}

module "fargate_guardrails" {
  source = "../../modules/fargate_guardrails"

  name_prefix = var.name_prefix
  environment = var.environment

  # Guardrails default: keep OFF until you want to test creation.
  enabled = false

  # Optional proof toggles (enable briefly, then destroy + revert):
  enable_budget      = true
  monthly_budget_usd = 10

  log_retention_days = 7

  # NAT stays OFF; wire NAT only after building my own VPC.
  enable_nat_gateway = var.enable_nat_gateway && var.nat_cost_acknowledged

  # ECS log group will be created by CloudFormation stack
  create_ecs_log_group = false
}

module "networking" {
  count  = var.enable_networking ? 1 : 0
  source = "../../modules/networking_vpc"

  name_prefix = var.name_prefix
  environment = var.environment
  owner       = var.owner
  project     = var.project

  # NAT requires explicit acknowledgment (your 0.4 rule)
  enable_nat_gateway = (var.enable_nat_gateway && var.nat_cost_acknowledged)
}

module "ec2_networking" {
  source = "../../modules/ec2_networking"

  name_prefix = var.name_prefix
  environment = var.environment

  enabled    = var.enable_ec2
  vpc_id     = module.networking[0].vpc_id
  subnet_ids = module.networking[0].public_subnet_ids

  instance_type = var.ec2_instance_type
  desired_count = var.ec2_desired_count

  # Default OFF (no inbound). If you ever need it briefly:
  allow_ssh = false
  ssh_cidr  = "0.0.0.0/32"
}

resource "aws_cloudformation_stack" "ecs_fargate_skeleton" {
  count = var.enable_cloudformation ? 1 : 0

  name = "${var.name_prefix}-ecs-skeleton"

  template_body = file("${path.module}/../../../cloudformation/stacks/ecs-fargate/skeleton.yml")

  capabilities = [
    "CAPABILITY_NAMED_IAM"
  ]

  parameters = {
    ArtifactBucket = "${var.name_prefix}-cfn-artifacts-${var.account_id}"
    ArtifactPrefix = var.name_prefix
    ContainerImage = var.container_image
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}

module "backend_ecr" {
  count  = var.enable_ecr ? 1 : 0
  source = "../../modules/ecr_repository"

  name = "${var.name_prefix}-backend"

  force_delete         = true
  scan_on_push         = true
  image_tag_mutability = "MUTABLE"

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}