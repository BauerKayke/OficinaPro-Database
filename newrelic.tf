# --- INTEGRAÇÃO NEW RELIC COM AWS ---
# Este arquivo cria a Role IAM necessária para que o New Relic possa
# se conectar à sua conta AWS e coletar métricas do CloudWatch para o RDS.

provider "newrelic" {
  account_id = var.newrelic_account_id
  api_key    = var.newrelic_api_key
  region     = "US" # Ou "EU"
}

# 1. Cria a integração entre New Relic e AWS
resource "newrelic_cloud_aws_integration" "aws_rds_integration" {
  account_id = var.newrelic_account_id
  
  # Habilita a coleta de métricas especificamente para o serviço RDS
  rds {
    fetch_tags           = true
    aws_regions          = [var.aws_region]
    tag_key              = "Project"
    tag_value            = "OficinaProTechChallenge"
  }
}

# 2. Gera um ARN de role para a integração
data "newrelic_cloud_aws_link_account" "link_account" {
  account_id = var.newrelic_account_id
  arn        = newrelic_cloud_aws_integration.aws_rds_integration.role_arn
  name       = "OficinaPro AWS Account"
}

