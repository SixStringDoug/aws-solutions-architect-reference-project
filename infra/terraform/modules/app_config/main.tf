# ----------------------------
# PRIMARY: SSM Parameter Store
# ----------------------------

resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.name_prefix}/db/host"
  type  = "String"
  value = var.db_host
  tags = {
    Environment = var.environment
    Project     = "tasktracker"
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/${var.name_prefix}/db/port"
  type  = "String"
  value = tostring(var.db_port)
  tags = {
    Environment = var.environment
    Project     = "tasktracker"
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

# SecureString uses the AWS-managed SSM KMS key by default (no custom KMS cost).
resource "aws_ssm_parameter" "db_username" {
  name  = "/${var.name_prefix}/db/username"
  type  = "SecureString"
  value = var.db_username
  tags = {
    Environment = var.environment
    Project     = "tasktracker"
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_ssm_parameter" "db_password" {
  count = var.db_password == null ? 0 : 1

  name  = "/${var.name_prefix}/db/password"
  type  = "SecureString"
  value = var.db_password
  tags = {
    Environment = var.environment
    Project     = "tasktracker"
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

# ------------------------------------------------------------
# OPTIONAL (COMMENTED OUT): Secrets Manager (proof-of-concept)
# ------------------------------------------------------------
# Why optional:
# - Recurring monthly cost per secret + API calls.
# - SSM SecureString is sufficient for dev/demo and cheaper.
#
# Uncomment to test, apply, verify in console, then destroy and re-comment.
# ------------------------------------------------------------

# resource "aws_secretsmanager_secret" "db_credentials" {
#   name = "${var.name_prefix}/db/credentials"
#   tags = {
#     Environment = var.environment
#     Project     = "tasktracker"
#     ManagedBy   = "terraform"
#     Owner       = "Doug"
#   }
# }

# resource "aws_secretsmanager_secret_version" "db_credentials" {
#   secret_id = aws_secretsmanager_secret.db_credentials.id
#   secret_string = jsonencode({
#     username = var.db_username
#     password = var.db_password
#     host     = var.db_host
#     port     = var.db_port
#   })
# }
