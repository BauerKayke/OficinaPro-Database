terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- DATA SOURCE: LER O ESTADO DA REDE ---
# Mantido caso precise de VPC ID para recursos futuros, mas não usado para DynamoDB.
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "fiap-oficinapro-ckm-tfstate"
    key    = "fase4/network/terraform.tfstate"
    region = var.aws_region
  }
}

# --- RECURSOS DO BANCO DE DADOS ---

# NOTA: A infraestrutura do RDS (Subnet Group, Security Group, DB Instance)
# foi migrada para o repositório 'OficinaPro-DevOps' (App Infra) para centralização.
# Este arquivo agora gerencia apenas recursos específicos de banco não cobertos lá,
# como tabelas DynamoDB de domínio específico (ver dynamodb.tf).
