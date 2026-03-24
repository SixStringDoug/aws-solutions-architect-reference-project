locals {
  account_id   = "403951654678" # your account id
  name_prefix  = "tasktracker-dev"
  state_bucket = "${local.name_prefix}-tfstate-${local.account_id}"
  lock_table   = "${local.name_prefix}-tfstate-lock"

  # CloudFormation artifact storage
  cfn_artifacts_bucket = "${local.name_prefix}-cfn-artifacts-${local.account_id}"
  cfn_artifacts_prefix = local.name_prefix
}

# -----------------------------
# Terraform State Infrastructure
# -----------------------------

resource "aws_s3_bucket" "tfstate" {
  bucket        = local.state_bucket
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_policy" "tfstate_deny_insecure" {
  bucket = aws_s3_bucket.tfstate.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.tfstate.arn,
        "${aws_s3_bucket.tfstate.arn}/*"
      ]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

resource "aws_dynamodb_table" "lock" {
  name         = local.lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# -----------------------------
# CloudFormation Artifacts Bucket
# -----------------------------

resource "aws_s3_bucket" "cfn_artifacts" {
  bucket        = local.cfn_artifacts_bucket
  force_destroy = true

  tags = {
    Project     = "tasktracker"
    Environment = "shared"
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_s3_bucket_versioning" "cfn_artifacts" {
  bucket = aws_s3_bucket.cfn_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cfn_artifacts" {
  bucket = aws_s3_bucket.cfn_artifacts.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "cfn_artifacts" {
  bucket                  = aws_s3_bucket.cfn_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "cfn_artifacts" {
  bucket = aws_s3_bucket.cfn_artifacts.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

# resource "aws_s3_bucket_policy" "cfn_artifacts_deny_insecure" {
#   bucket = aws_s3_bucket.cfn_artifacts.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Sid       = "DenyInsecureTransport"
#       Effect    = "Deny"
#       Principal = "*"
#       Action    = "s3:*"
#       Resource = [
#         aws_s3_bucket.cfn_artifacts.arn,
#         "${aws_s3_bucket.cfn_artifacts.arn}/*"
#       ]
#       Condition = { Bool = { "aws:SecureTransport" = "false" } }
#     }]
#   })
# }

# resource "aws_s3_bucket_policy" "cfn_artifacts_allow_cloudformation" {
#   bucket = aws_s3_bucket.cfn_artifacts.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "AllowCloudFormationRead"
#         Effect    = "Allow"
#         Principal = "*"
#         Action    = "s3:GetObject"
#         Resource  = "${aws_s3_bucket.cfn_artifacts.arn}/*"
#       }
#     ]
#   })
# }

resource "aws_s3_bucket_policy" "cfn_artifacts_policy" {
  bucket = aws_s3_bucket.cfn_artifacts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.cfn_artifacts.arn,
          "${aws_s3_bucket.cfn_artifacts.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowCloudFormationRead"
        Effect = "Allow"
        Principal = {
          Service = "cloudformation.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.cfn_artifacts.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })
}

# -----------------------------
# Upload reusable CloudFormation components automatically
# -----------------------------

resource "aws_s3_object" "ecs_fargate_network_component" {
  bucket       = aws_s3_bucket.cfn_artifacts.id
  key          = "${local.cfn_artifacts_prefix}/components/networking-vpc.yml"
  source       = "${path.module}/../../../cloudformation/components/networking-vpc.yml"
  etag         = filemd5("${path.module}/../../../cloudformation/components/networking-vpc.yml")
  content_type = "text/yaml"
}

resource "aws_s3_object" "ecs_fargate_cluster_component" {
  bucket       = aws_s3_bucket.cfn_artifacts.id
  key          = "${local.cfn_artifacts_prefix}/components/ecs-fargate/cluster.yml"
  source       = "${path.module}/../../../cloudformation/components/ecs-fargate/cluster.yml"
  etag         = filemd5("${path.module}/../../../cloudformation/components/ecs-fargate/cluster.yml")
  content_type = "text/yaml"
}

resource "aws_s3_object" "ecs_fargate_logs_component" {
  bucket       = aws_s3_bucket.cfn_artifacts.id
  key          = "${local.cfn_artifacts_prefix}/components/ecs-fargate/logs.yml"
  source       = "${path.module}/../../../cloudformation/components/ecs-fargate/logs.yml"
  etag         = filemd5("${path.module}/../../../cloudformation/components/ecs-fargate/logs.yml")
  content_type = "text/yaml"
}

resource "aws_s3_object" "ecs_fargate_service_component" {
  bucket       = aws_s3_bucket.cfn_artifacts.id
  key          = "${local.cfn_artifacts_prefix}/components/ecs-fargate/service.yml"
  source       = "${path.module}/../../../cloudformation/components/ecs-fargate/service.yml"
  etag         = filemd5("${path.module}/../../../cloudformation/components/ecs-fargate/service.yml")
  content_type = "text/yaml"
}

# -----------------------------
# Outputs
# -----------------------------

output "state_bucket" { value = aws_s3_bucket.tfstate.bucket }

output "lock_table" { value = aws_dynamodb_table.lock.name }

output "cfn_artifacts_bucket" {
  value = aws_s3_bucket.cfn_artifacts.bucket
}