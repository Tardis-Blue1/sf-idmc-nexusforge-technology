# Placeholder secret shells for connector credentials. Values set out-of-band.
variable "name_prefix" {
  type = string
}

variable "secret_ids" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_secretsmanager_secret" "connector" {
  for_each = toset(var.secret_ids)

  name                    = each.value
  description             = "NexusForge connector secret placeholder (${each.value}). Value injected out-of-band for Salesforce / Informatica IDMC."
  recovery_window_in_days = 0
  tags                    = var.tags
}

# Intentionally NO aws_secretsmanager_secret_version with plaintext.

output "secret_arns" {
  value = { for k, s in aws_secretsmanager_secret.connector : k => s.arn }
}

output "secret_names" {
  value = [for s in aws_secretsmanager_secret.connector : s.name]
}
