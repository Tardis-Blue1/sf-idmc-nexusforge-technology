# NexusForge Systems — supporting cloud IaC for Salesforce + Informatica IDMC
# Secret VALUES are never managed here; only references / empty secret shells.

locals {
  name = "${var.project_prefix}-${var.environment}"
}

module "secrets" {
  source = "./modules/secrets"

  name_prefix = local.name
  secret_ids  = var.secret_name_prefixes
  tags = {
    Component = "secrets-refs"
  }
}

module "logging" {
  source = "./modules/logging"

  enabled       = var.enable_secure_agent_log_bucket
  name_prefix   = local.name
  force_destroy = var.environment != "prod"
  tags = {
    Component = "idmc-secure-agent-logs"
  }
}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix        = local.name
  log_retention_days = var.log_retention_days
  tags = {
    Component = "integration-observability"
  }
}
