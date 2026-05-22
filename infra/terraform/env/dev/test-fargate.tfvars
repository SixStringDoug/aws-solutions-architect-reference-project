# -----------------------------
# Fargate Compute Test
# -----------------------------

enable_networking           = true
enable_ec2                  = false
enable_ec2_alb              = false
enable_nat_gateway          = true
nat_cost_acknowledged       = true
fargate_use_private_subnets = true
fargate_desired_count       = 2
enable_cloudformation       = false
enable_ecr                  = true

ec2_instance_type       = "t3.micro"
ec2_desired_count       = 1
ec2_use_private_subnets = false

account_id = "403951654678"

container_image = "403951654678.dkr.ecr.us-east-2.amazonaws.com/tasktracker-dev-backend:ph4"