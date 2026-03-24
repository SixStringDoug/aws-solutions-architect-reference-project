locals {
  tags = {
    Environment = var.environment
    Project     = "tasktracker"
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

# ------------------------------------------------------------
# Guardrail 1: CloudWatch log group (future ECS tasks will log here)
# Guardrail: retention is finite to prevent cost creep.
#
# NOTE:
# When ECS infrastructure is deployed via CloudFormation,
# CloudFormation owns the log group to avoid IaC ownership conflicts.
# ------------------------------------------------------------
variable "create_ecs_log_group" {
  description = "Allow Terraform to create the ECS log group. Disable if CloudFormation manages ECS."
  type        = bool
  default     = true
}

resource "aws_cloudwatch_log_group" "ecs" {
  count = (var.enabled && var.create_ecs_log_group) ? 1 : 0

  name              = "/${var.name_prefix}/ecs"
  retention_in_days = var.log_retention_days

  tags = local.tags
}

# ------------------------------------------------------------
# Guardrail 2: Budget alarm (optional)
# This helps catch “oops I left services running” quickly.
# ------------------------------------------------------------
resource "aws_budgets_budget" "monthly" {
  count        = (var.enabled && var.enable_budget) ? 1 : 0
  name         = "${var.name_prefix}-monthly-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # If I want email notifications later, I’ll add notifications block then.
}

# ------------------------------------------------------------
# NAT Gateway (COST TRAP) — demonstration only; keep disabled by default
#
# Why:
# - NAT Gateway has an hourly charge plus per-GB data processing charges.
# - It is one of the most common sources of unintended AWS spend.
#
# This block is intentionally left disabled so you can demonstrate
# that you understand how to provision it while also showing
# cost awareness and disciplined guardrails.
#
# If you choose to test:
# 1) Enable the toggle.
# 2) Provide a valid public subnet ID (after building a dedicated VPC).
# 3) Apply, verify, then destroy immediately.
#
# Do not leave NAT enabled unless actively required.
# ------------------------------------------------------------

# NOTE: A real NAT requires a VPC, public subnet, EIP, IGW, route table wiring.
# This is NOT being built that now (Currently using default VPC).
# When VPC is built later, This will be wired properly.

# resource "aws_eip" "nat" {
#   count = (var.enabled && var.enable_nat_gateway) ? 1 : 0
#   domain = "vpc"
#   tags = local.tags
# }

# resource "aws_nat_gateway" "this" {
#   count         = (var.enabled && var.enable_nat_gateway) ? 1 : 0
#   allocation_id = aws_eip.nat[0].id
#   subnet_id     = "<PUBLIC_SUBNET_ID>"
#   tags          = local.tags
# }