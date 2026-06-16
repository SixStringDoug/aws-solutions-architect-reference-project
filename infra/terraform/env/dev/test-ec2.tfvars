# -----------------------------
# Shared Infrastructure
# -----------------------------

enable_networking     = true
enable_nat_gateway    = true
nat_cost_acknowledged = true
enable_ecr            = false

account_id = "403951654678"

container_image = "403951654678.dkr.ecr.us-east-2.amazonaws.com/tasktracker-dev-backend:ph4"

rds_backup_retention_period = 1

# -----------------------------
# Fargate Architecture (Inactive)
# -----------------------------

enable_cloudformation = false

fargate_use_private_subnets = false
fargate_desired_count       = 1

fargate_enable_service_auto_scaling = false
fargate_service_min_capacity        = 1
fargate_service_max_capacity        = 1
fargate_service_cpu_target_value    = 60

# -----------------------------
# EC2 Architecture (Active)
# -----------------------------

enable_ec2     = true
enable_ec2_alb = true

ec2_instance_type       = "t3.micro"
ec2_desired_count       = 2
ec2_use_private_subnets = true

