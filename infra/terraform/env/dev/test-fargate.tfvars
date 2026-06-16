# -----------------------------
# Shared Infrastructure
# -----------------------------

enable_networking     = true
enable_nat_gateway    = true
nat_cost_acknowledged = true
enable_ecr            = true

account_id = "403951654678"

container_image = "403951654678.dkr.ecr.us-east-2.amazonaws.com/tasktracker-dev-backend:ph4"

rds_backup_retention_period = 1

# -----------------------------
# Fargate Architecture (Active)
# -----------------------------

enable_cloudformation = false

fargate_use_private_subnets = true
fargate_desired_count       = 2

fargate_enable_service_auto_scaling = true
fargate_service_min_capacity        = 2
fargate_service_max_capacity        = 3
fargate_service_cpu_target_value    = 60

# -----------------------------
# EC2 Architecture (Inactive)
# -----------------------------

enable_ec2     = false
enable_ec2_alb = false

ec2_instance_type       = "t3.micro"
ec2_desired_count       = 1
ec2_use_private_subnets = false

