module "attachments_bucket" {
  source      = "../../modules/s3_attachments"
  bucket_name = "${var.name_prefix}-attachments"
}

resource "aws_s3_object" "backend_jar" {
  bucket = module.attachments_bucket.bucket_name
  key    = "tasktracker.jar"
  source = "${path.module}/../../../../artifacts/tasktracker.jar"
  etag   = filemd5("${path.module}/../../../../artifacts/tasktracker.jar")

  content_type = "application/java-archive"
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

  vpc_id     = module.networking[0].vpc_id
  subnet_ids = module.networking[0].public_subnet_ids

  db_username = var.db_username
  db_password = var.db_password

  db_name = "tasktrackerdevpostgres"

  backup_retention_period = var.rds_backup_retention_period

  # Cost toggles (default cheap)
  multi_az                    = false
  use_managed_master_password = false

  # No public DB access; RDS ingress is controlled by security group source rules.
  allowed_cidr = "0.0.0.0/32"
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
  source     = "../../modules/ec2_networking"
  depends_on = [aws_s3_object.backend_jar]

  name_prefix = var.name_prefix
  environment = var.environment

  enabled    = var.enable_ec2
  enable_alb = var.enable_ec2_alb

  vpc_id                      = module.networking[0].vpc_id
  alb_subnet_ids              = module.networking[0].public_subnet_ids
  instance_subnet_ids         = var.ec2_use_private_subnets ? module.networking[0].private_subnet_ids : module.networking[0].public_subnet_ids
  associate_public_ip_address = !var.ec2_use_private_subnets

  instance_type = var.ec2_instance_type
  desired_count = var.ec2_desired_count

  artifact_bucket_name = module.attachments_bucket.bucket_name
  db_name              = "tasktrackerdevpostgres"
  ssm_parameter_paths  = module.app_config.ssm_parameter_paths

  # Default OFF (no inbound). If you ever need it briefly:
  allow_ssh = false
  ssh_cidr  = "0.0.0.0/32"

  allow_http = false
  http_cidr  = "0.0.0.0/32"

  user_data = <<-EOF
#!/bin/bash
# --------------------------------------------
# EC2 Bootstrap Script
# Installs Java, downloads app JAR from S3,
# reads DB config from SSM, and starts app
# --------------------------------------------
set -e
exec > /var/log/user-data.log 2>&1

dnf update -y
dnf install -y java-17-amazon-corretto awscli
rpm -Uvh https://amazoncloudwatch-agent-us-east-2.s3.us-east-2.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm

mkdir -p /opt/tasktracker
cd /opt/tasktracker

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/tasktracker-dev/ec2",
            "log_stream_name": "{instance_id}/user-data.log"
          },
          {
            "file_path": "/opt/tasktracker/app.log",
            "log_group_name": "/tasktracker-dev/ec2",
            "log_stream_name": "{instance_id}/app.log"
          }
        ]
      }
    }
  }
}
CWCONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

aws s3 cp s3://${module.attachments_bucket.bucket_name}/tasktracker.jar tasktracker.jar

DB_HOST=$(aws ssm get-parameter --name "${module.app_config.ssm_parameter_paths.db_host}" --query 'Parameter.Value' --output text --region ${var.aws_region})
DB_PORT=$(aws ssm get-parameter --name "${module.app_config.ssm_parameter_paths.db_port}" --query 'Parameter.Value' --output text --region ${var.aws_region})
DB_USERNAME=$(aws ssm get-parameter --name "${module.app_config.ssm_parameter_paths.db_username}" --with-decryption --query 'Parameter.Value' --output text --region ${var.aws_region})
DB_PASSWORD=$(aws ssm get-parameter --name "${module.app_config.ssm_parameter_paths.db_password}" --with-decryption --query 'Parameter.Value' --output text --region ${var.aws_region})

DB_URL="jdbc:postgresql://$${DB_HOST}:$${DB_PORT}/tasktrackerdevpostgres"

nohup env \
  SPRING_PROFILES_ACTIVE=ec2 \
  DB_URL="$DB_URL" \
  DB_USERNAME="$DB_USERNAME" \
  DB_PASSWORD="$DB_PASSWORD" \
  java -jar tasktracker.jar > app.log 2>&1 &
EOF
}

resource "aws_security_group_rule" "rds_from_ec2" {
  count = var.enable_ec2 ? 1 : 0

  type                     = "ingress"
  security_group_id        = module.rds.security_group_id
  source_security_group_id = module.ec2_networking.security_group_id

  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"

  description = "Allow PostgreSQL traffic from EC2 application security group"
}

resource "aws_security_group" "fargate_alb" {
  count       = var.enable_cloudformation ? 1 : 0
  name        = "${var.name_prefix}-sg-fargate-alb"
  description = "ALB SG for Fargate"
  vpc_id      = module.networking[0].vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Public HTTP access to ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "fargate_tasks" {
  count       = var.enable_cloudformation ? 1 : 0
  name        = "${var.name_prefix}-sg-fargate-tasks"
  description = "Fargate task SG"
  vpc_id      = module.networking[0].vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.fargate_alb[0].id]
    description     = "Allow ALB to reach ECS tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rds_from_fargate" {
  count = var.enable_cloudformation ? 1 : 0

  type      = "ingress"
  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"

  # This comes from CloudFormation stack outputs
  security_group_id        = module.rds.security_group_id
  source_security_group_id = aws_security_group.fargate_tasks[0].id

  description = "Allow PostgreSQL traffic from Fargate tasks"
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

    VpcId                    = module.networking[0].vpc_id
    PublicSubnetIds          = join(",", module.networking[0].public_subnet_ids)
    TaskSubnetIds            = join(",", var.fargate_use_private_subnets ? module.networking[0].private_subnet_ids : module.networking[0].public_subnet_ids)
    AssignPublicIp           = var.fargate_use_private_subnets ? "DISABLED" : "ENABLED"
    DesiredCount             = tostring(var.fargate_desired_count)
    EnableServiceAutoScaling = tostring(var.fargate_enable_service_auto_scaling)
    ServiceMinCapacity       = tostring(var.fargate_service_min_capacity)
    ServiceMaxCapacity       = tostring(var.fargate_service_max_capacity)
    ServiceCpuTargetValue    = tostring(var.fargate_service_cpu_target_value)
    AlbSecurityGroupId       = aws_security_group.fargate_alb[0].id
    TasksSecurityGroupId     = aws_security_group.fargate_tasks[0].id
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