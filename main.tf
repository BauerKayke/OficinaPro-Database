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
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "fiap-oficinapro-ckm-tfstate"
    key    = "fase4/network/terraform.tfstate"
    region = var.aws_region
  }
}

# --- RECURSOS DO BANCO DE DADOS ---

# RDS Subnet Group
resource "aws_db_subnet_group" "budget_db_subnet_group" {
  name       = "${var.project_name}-budget-db-subnet-group"
  subnet_ids = data.terraform_remote_state.network.outputs.public_subnet_ids # Lê da rede

  tags = {
    Name = "${var.project_name}-budget-db-subnet-group"
  }
}

# Security Group otimizado para RDS
resource "aws_security_group" "budget_db_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group para o banco de dados RDS PostgreSQL"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id # Lê da rede

  # Regra de entrada: Acesso PostgreSQL
  # IMPORTANTE: Como a aplicação ainda não tem SG, liberamos inicialmente a VPC.
  # Quando a app for criada, o SG dela pode ser adicionado aqui em uma segunda execução
  # ou via regra avulsa 'aws_security_group_rule' no módulo da app.
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"] # Temporário: libera para a VPC inteira
    description     = "Acesso PostgreSQL da VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# RDS Instance otimizada (t3.micro - Free Tier eligible)
resource "aws_db_instance" "budget_db" {
  identifier = "oficinapro-consolidated-db"  # Nome consistente com o atual

  engine         = "postgres"
  engine_version = "16.6"  # Versão mais recente e mais barata
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = false

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.budget_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.budget_db_subnet_group.name

  backup_retention_period    = 1
  skip_final_snapshot        = true
  deletion_protection        = false
  publicly_accessible        = false
  performance_insights_enabled = false
  monitoring_interval        = 0

  tags = {
    Name = "oficinapro-consolidated-db"
  }
}
