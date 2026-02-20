# ===============================================
# DynamoDB Table - Payment Service (NoSQL)
# Tech Challenge FIAP - Fase 4
# ===============================================
#
# Requisito: "Uso de pelo menos um banco não relacional (NoSQL)"
#
# Este módulo cria a tabela DynamoDB para o Payment Service,
# substituindo a persistência em PostgreSQL e atendendo ao
# requisito obrigatório de NoSQL da Fase 4.

resource "aws_dynamodb_table" "payments" {
  name           = "oficinapro-payments"
  billing_mode   = "PAY_PER_REQUEST"  # On-demand (Free tier friendly)
  hash_key       = "payment_id"
  
  # Atributos
  attribute {
    name = "payment_id"
    type = "S"  # String
  }
  
  attribute {
    name = "order_id"
    type = "N"  # Number
  }
  
  # Global Secondary Index para buscar pagamentos por order_id
  global_secondary_index {
    name            = "OrderIdIndex"
    hash_key        = "order_id"
    projection_type = "ALL"  # Retorna todos os atributos
  }
  
  # Point-in-time recovery (backup automático)
  point_in_time_recovery {
    enabled = true
  }
  
  # Server-side encryption
  server_side_encryption {
    enabled     = true
    kms_key_arn = null  # Usa AWS managed key
  }
  
  # TTL (Time To Live) - opcional, pode ser usado para expirar pagamentos antigos
  # ttl {
  #   attribute_name = "expires_at"
  #   enabled        = true
  # }
  
  tags = {
    Name        = "OficinaPro Payments"
    Project     = "OficinaPro"
    Environment = "production"
    Service     = "payment-service"
    Database    = "NoSQL"
    Requirement = "Fase 4 - NoSQL Database"
    ManagedBy   = "Terraform"
  }
}

# Output: ARN da tabela
output "dynamodb_payments_table_arn" {
  description = "ARN da tabela DynamoDB de pagamentos"
  value       = aws_dynamodb_table.payments.arn
}

# Output: Nome da tabela
output "dynamodb_payments_table_name" {
  description = "Nome da tabela DynamoDB de pagamentos"
  value       = aws_dynamodb_table.payments.name
}

# Output: Stream ARN (caso queira usar DynamoDB Streams futuramente)
output "dynamodb_payments_stream_arn" {
  description = "ARN do stream da tabela (se habilitado)"
  value       = try(aws_dynamodb_table.payments.stream_arn, "")
}
