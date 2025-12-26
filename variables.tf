# Variáveis específicas para a infraestrutura do banco de dados

variable "aws_region" {
  description = "Região AWS para o banco de dados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto (usado nos nomes dos recursos)"
  type        = string
  default     = "fiap-oficinapro-kb"
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "oficinapro"
}

variable "db_username" {
  description = "Usuário do banco de dados"
  type        = string
  default     = "oficinapro_user"
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
}

# --- Variáveis New Relic ---

variable "newrelic_account_id" {
  description = "ID da conta New Relic"
  type        = string
}

variable "newrelic_api_key" {
  description = "Chave de API de Usuário do New Relic (User API Key)"
  type        = string
  sensitive   = true
}
