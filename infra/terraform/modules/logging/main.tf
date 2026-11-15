variable "enabled" {
  type    = bool
  default = true
}

variable "name_prefix" {
  type = string
}

variable "force_destroy" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_s3_bucket" "secure_agent_logs" {
  count = var.enabled ? 1 : 0

  bucket        = "${var.name_prefix}-idmc-secure-agent-logs"
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "secure_agent_logs" {
  count = var.enabled ? 1 : 0

  bucket                  = aws_s3_bucket.secure_agent_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_agent_logs" {
  count = var.enabled ? 1 : 0

  bucket = aws_s3_bucket.secure_agent_logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "bucket_id" {
  value = var.enabled ? aws_s3_bucket.secure_agent_logs[0].id : null
}

output "bucket_arn" {
  value = var.enabled ? aws_s3_bucket.secure_agent_logs[0].arn : null
}
