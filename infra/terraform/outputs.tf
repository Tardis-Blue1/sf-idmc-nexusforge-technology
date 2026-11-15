output "secret_arns" {
  description = "ARNs of Secrets Manager placeholders for Informatica IDMC and Salesforce connectors (no values)."
  value       = module.secrets.secret_arns
}

output "secure_agent_log_bucket" {
  description = "Optional S3 bucket for Informatica IDMC Secure Agent logs."
  value       = module.logging.bucket_id
}

output "integration_log_group" {
  description = "CloudWatch log group placeholder for integration metrics."
  value       = module.monitoring.log_group_name
}

output "dashboard_name" {
  description = "CloudWatch dashboard placeholder name."
  value       = module.monitoring.dashboard_name
}

output "environment" {
  description = "Deployed environment label."
  value       = var.environment
}
