# Saídas de dados da infraestrutura do banco de dados

output "db_instance_address" {
  description = "O endereço (endpoint) da instância do banco de dados."
  value       = aws_db_instance.budget_db.address
}

output "db_instance_port" {
  description = "A porta do banco de dados."
  value       = aws_db_instance.budget_db.port
}

output "db_instance_name" {
  description = "O nome do banco de dados (DB name)."
  value       = aws_db_instance.budget_db.db_name
}

output "db_instance_username" {
  description = "O nome de usuário do banco de dados."
  value       = aws_db_instance.budget_db.username
}

output "db_security_group_id" {
  description = "O ID do Security Group do banco de dados."
  value       = aws_security_group.budget_db_sg.id
}
