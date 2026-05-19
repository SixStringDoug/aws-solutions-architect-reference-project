# -----------------------------
# EC2 Compute Test
# -----------------------------

enable_networking     = true
enable_ec2            = true
enable_ec2_alb        = true
enable_nat_gateway    = true
nat_cost_acknowledged = true
enable_cloudformation = false
enable_ecr            = false

ec2_instance_type       = "t3.micro"
ec2_desired_count       = 2
ec2_use_private_subnets = true

account_id = "403951654678"

# container_image = "403951654678.dkr.ecr.us-east-2.amazonaws.com/tasktracker-dev-backend:ph3"