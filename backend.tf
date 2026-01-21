terraform {
  backend "s3" {
    bucket         = "fiap-oficinapro-ckm-tfstate"
    key            = "oficinapro/database/terraform.tfstate" # <-- Chave específica para o estado do banco
    region         = "us-east-1"
    dynamodb_table = "oficinapro-tfstate-lock-table"
    encrypt        = true
  }
}
