resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-dev-objects"
    status = "Enabled"

    filter {}

    expiration { days = 30 }

    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_policy" "deny_insecure_transport" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*"
      ]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

# -------------------------------------------------------------------
# OPTIONAL (COMMENTED OUT): SSE-KMS for production-grade encryption
#
# Why optional:
# - KMS adds per-request costs and operational overhead.
# - For dev/demo, SSE-S3 is usually sufficient and cheaper.
#
# If you enable this:
# 1) Uncomment the KMS key resource below.
# 2) Replace the SSE-S3 encryption block above with the SSE-KMS block below.
# 3) Apply, verify, then destroy (or re-comment) if you're keeping costs minimal.
#
# NOTE: For true production, you'd add stricter key policies and key rotation choices.
# -------------------------------------------------------------------

# resource "aws_kms_key" "s3" {
#   description             = "KMS key for ${var.bucket_name} (attachments)"
#   deletion_window_in_days = 7
#   enable_key_rotation     = true
# }

# resource "aws_kms_alias" "s3" {
#   name          = "alias/${var.bucket_name}"
#   target_key_id = aws_kms_key.s3.key_id
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
#   bucket = aws_s3_bucket.this.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm     = "aws:kms"
#       kms_master_key_id = aws_kms_key.s3.arn
#     }
#   }
# }

# -------------------------------------------------------------------
# OPTIONAL (COMMENTED OUT): CloudTrail S3 DATA EVENTS for this bucket
#
# Why optional:
# - S3 data events can get expensive quickly with real traffic.
# - For short verification windows, it can be enabled briefly and then destroyed.
#
# If you enable this:
# - It will create a dedicated CloudTrail + S3 log bucket (also versioned).
# - It will record object-level access events for this attachments bucket.
# -------------------------------------------------------------------

# locals {
#   cloudtrail_name       = "${var.bucket_name}-trail"
#   cloudtrail_log_bucket = "${var.bucket_name}-trail-logs"
# }

# resource "aws_s3_bucket" "cloudtrail_logs" {
#   bucket        = local.cloudtrail_log_bucket
#   force_destroy = true
# }

# resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
#   bucket                  = aws_s3_bucket.cloudtrail_logs.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
#   bucket = aws_s3_bucket.cloudtrail_logs.id
#   versioning_configuration { status = "Enabled" }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
#   bucket = aws_s3_bucket.cloudtrail_logs.id
#   rule {
#     apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
#   }
# }

# data source to get account ID
# data "aws_caller_identity" "current" {}

# resource "aws_s3_bucket_policy" "cloudtrail_logs" {
#   bucket = aws_s3_bucket.cloudtrail_logs.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid      = "AWSCloudTrailAclCheck"
#         Effect   = "Allow"
#         Principal = { Service = "cloudtrail.amazonaws.com" }
#         Action   = "s3:GetBucketAcl"
#         Resource = aws_s3_bucket.cloudtrail_logs.arn
#       },
#       {
#         Sid      = "AWSCloudTrailWrite"
#         Effect   = "Allow"
#         Principal = { Service = "cloudtrail.amazonaws.com" }
#         Action   = "s3:PutObject"
#         Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
#         Condition = {
#           StringEquals = {
#             "s3:x-amz-acl" = "bucket-owner-full-control"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_cloudtrail" "attachments_data_events" {
#   name                          = local.cloudtrail_name
#   s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.bucket
#   include_global_service_events = false
#   is_multi_region_trail         = false
#   enable_logging                = true
#
#   depends_on = [
#     aws_s3_bucket_policy.cloudtrail_logs
#   ]
#
#   event_selector {
#     read_write_type           = "All"
#     include_management_events = false
#
#     data_resource {
#       type   = "AWS::S3::Object"
#       values = ["${aws_s3_bucket.this.arn}/"]
#     }
#   }
# }
