variable "name_prefix" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_cloudwatch_log_group" "integration" {
  name              = "/nexusforge/${var.name_prefix}/integration"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_dashboard" "placeholder" {
  dashboard_name = "${var.name_prefix}-sf-idmc"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# NexusForge Systems — Salesforce + Informatica IDMC\nPlaceholder dashboard for sync lag, MDM match %, DQ fail rate, agent allow/deny."
        }
      }
    ]
  })
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.integration.name
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.placeholder.dashboard_name
}
