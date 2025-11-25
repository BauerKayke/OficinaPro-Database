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

# --- DATA SOURCES ---
# Busca por recursos de rede que são criados pelo repositório 'oficinapro-infra'

data "aws_vpc" "existing_vpc" {
  tags = {
    Name = "${var.project_name}-budget-vpc"
  }
}

data "aws_subnets" "existing_public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }
  tags = {
    Name = "${var.project_name}-budget-public-subnet*"
  }
}

data "aws_security_group" "k3s_sg" {
  tags = {
    Name = "${var.project_name}-k3s-sg"
  }
}


# --- RECURSOS DO BANCO DE DADOS ---

# RDS Subnet Group
resource "aws_db_subnet_group" "budget_db_subnet_group" {
  name       = "${var.project_name}-budget-db-subnet-group"
  subnet_ids = data.aws_subnets.existing_public_subnets.ids

  tags = {
    Name = "${var.project_name}-budget-db-subnet-group"
  }
}

# Security Group otimizado para RDS
resource "aws_security_group" "budget_db_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group para o banco de dados RDS PostgreSQL"
  vpc_id      = data.aws_vpc.existing_vpc.id

  # Acesso PostgreSQL apenas do cluster K3s
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.aws_security_group.k3s_sg.id]
    description     = "Acesso PostgreSQL apenas do security group do K3s"
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
  identifier = "${var.project_name}-budget-db"

  engine         = "postgres"
  engine_version = "15.10"
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
    Name = "${var.project_name}-budget-db"
  }
}
