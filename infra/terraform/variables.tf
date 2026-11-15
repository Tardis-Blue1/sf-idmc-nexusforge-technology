variable "aws_region" {
  type        = string
  description = "AWS region for NexusForge non-prod supporting resources."
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name (nonprod, prod)."
  default     = "nonprod"
}

variable "project_prefix" {
  type        = string
  description = "Name prefix for resources."
  default     = "nexusforge"
}

variable "common_tags" {
  type        = map(string)
  description = "Additional resource tags."
  default     = {}
}

variable "enable_secure_agent_log_bucket" {
  type        = bool
  description = "Optional S3 bucket for Informatica IDMC Secure Agent logs."
  default     = true
}

variable "secret_name_prefixes" {
  type        = list(string)
  description = "Logical secret name prefixes (values live in Secrets Manager; never in repo)."
  default = [
    "nexusforge/nonprod/stripe_api",
    "nexusforge/nonprod/salesforce_integration",
    "nexusforge/nonprod/idmc_mdm",
    "nexusforge/nonprod/idmc_dq",
    "nexusforge/nonprod/device_registry",
    "nexusforge/nonprod/zendesk",
    "nexusforge/nonprod/agent_writeback_oauth"
  ]
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention for integration/monitor placeholders."
  default     = 30
}
