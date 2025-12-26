# --- INTEGRAÇÃO NEW RELIC COM AWS ---

provider "newrelic" {
  account_id = var.newrelic_account_id
  api_key    = var.newrelic_api_key
  region     = "US"
}

# Data source para pegar o ID da conta AWS atual
data "aws_caller_identity" "current" {}

# 1. Criar a Role IAM na AWS para o New Relic
resource "aws_iam_role" "newrelic_integration_role" {
  name = "NewRelicInfrastructure-Integrations-${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::754728514883:root" # ID da conta do New Relic (US region default)
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.newrelic_account_id
          }
        }
      }
    ]
  })
}

# Anexar a política ReadOnlyAccess à role (necessário para o New Relic ler métricas)
resource "aws_iam_role_policy_attachment" "newrelic_readonly" {
  role       = aws_iam_role.newrelic_integration_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# 2. Vincular a conta AWS ao New Relic usando a Role criada
resource "newrelic_cloud_aws_link_account" "link_account" {
  account_id             = var.newrelic_account_id
  arn                    = aws_iam_role.newrelic_integration_role.arn
  metric_collection_mode = "PULL" # API Polling
  name                   = "OficinaPro AWS Account"
  
  depends_on = [aws_iam_role.newrelic_integration_role]
}

# 3. Habilitar a integração de RDS
resource "newrelic_cloud_aws_integrations" "aws_rds_integration" {
  account_id        = var.newrelic_account_id
  linked_account_id = newrelic_cloud_aws_link_account.link_account.id

  rds {
    fetch_tags               = true
    aws_regions              = [var.aws_region]
    tag_key                  = "Project"
    tag_value                = "OficinaProTechChallenge"
    metrics_polling_interval = 300
  }
}
