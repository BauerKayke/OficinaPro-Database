# 🗄️ OficinaPro - Database Infrastructure

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://www.terraform.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?logo=postgresql)](https://www.postgresql.org/)
[![AWS RDS](https://img.shields.io/badge/AWS-RDS-FF9900?logo=amazon-aws)](https://aws.amazon.com/rds/)

## 📋 Descrição

Este repositório contém a **Infrastructure as Code (IaC)** para o banco de dados **PostgreSQL** do projeto OficinaPro, utilizando **AWS RDS** (Relational Database Service) gerenciado via Terraform.

## 🎯 Propósito

- Provisionar instância RDS PostgreSQL na AWS
- Configurar Security Groups para acesso seguro
- Integrar com a infraestrutura de rede existente (VPC do OficinaPro-DevOps)
- Garantir alta disponibilidade e backup automático

## 🛠️ Tecnologias Utilizadas

| Tecnologia | Versão | Descrição |
|------------|--------|-----------|
| **Terraform** | >= 1.0 | Infrastructure as Code |
| **AWS Provider** | ~> 5.0 | Provider para recursos AWS |
| **PostgreSQL** | 15.10 | Engine do banco de dados |
| **AWS RDS** | db.t3.micro | Instância gerenciada (Free Tier) |

## 📁 Estrutura do Repositório

```
OficinaPro-Database/
├── main.tf           # Recursos principais (RDS, Security Group, Subnet Group)
├── variables.tf      # Variáveis de configuração
├── outputs.tf        # Outputs do Terraform
├── backend.tf        # Configuração do backend remoto (S3)
└── README.md         # Esta documentação
```

## 🏗️ Arquitetura do Banco de Dados

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS VPC                                         │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    DB Subnet Group (Multi-AZ)                          │  │
│  │                                                                        │  │
│  │  ┌─────────────────────┐    ┌─────────────────────┐                   │  │
│  │  │   Public Subnet 1   │    │   Public Subnet 2   │                   │  │
│  │  │   (AZ: us-east-1a)  │    │   (AZ: us-east-1b)  │                   │  │
│  │  │                     │    │                     │                   │  │
│  │  │  ┌───────────────┐  │    │                     │                   │  │
│  │  │  │     RDS       │  │    │     (Standby)       │                   │  │
│  │  │  │  PostgreSQL   │  │    │                     │                   │  │
│  │  │  │   (Primary)   │  │    │                     │                   │  │
│  │  │  └───────────────┘  │    │                     │                   │  │
│  │  └─────────────────────┘    └─────────────────────┘                   │  │
│  │                                                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                     │                                        │
│                                     │ Port 5432                              │
│                                     ▼                                        │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                        Security Group                                  │  │
│  │  • Ingress: 5432/TCP from VPC (10.0.0.0/16)                           │  │
│  │  • Egress: All traffic allowed                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  Conexões permitidas:                                                        │
│  • EC2 (K3s) → RDS (Core Domain Service)                                    │
│  • Lambda → RDS (Auth Gateway)                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🗃️ Modelo de Dados

O banco de dados suporta as seguintes entidades principais:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          MODELO ENTIDADE-RELACIONAMENTO                      │
│                                                                              │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐                   │
│  │   USUARIO   │     │   CLIENTE   │     │   VEICULO   │                   │
│  │─────────────│     │─────────────│     │─────────────│                   │
│  │ id          │     │ id          │     │ id          │                   │
│  │ email       │     │ nome        │     │ placa       │                   │
│  │ senha_hash  │     │ cpf         │     │ modelo      │                   │
│  │ nome        │     │ telefone    │     │ ano         │                   │
│  │ role        │     │ email       │     │ cliente_id  │←──┐               │
│  └─────────────┘     │ endereco    │     └─────────────┘   │               │
│                      └──────┬──────┘           │           │               │
│                             │                  │           │               │
│                             │ 1:N              │ 1:N       │               │
│                             ▼                  ▼           │               │
│                      ┌─────────────────────────────┐       │               │
│                      │      ORDEM_SERVICO          │───────┘               │
│                      │─────────────────────────────│                       │
│                      │ id                          │                       │
│                      │ cliente_id                  │                       │
│                      │ veiculo_id                  │                       │
│                      │ status                      │                       │
│                      │ descricao                   │                       │
│                      │ data_abertura               │                       │
│                      │ data_conclusao              │                       │
│                      │ valor_total                 │                       │
│                      └──────────────┬──────────────┘                       │
│                                     │                                       │
│                    ┌────────────────┼────────────────┐                     │
│                    │ 1:N            │ 1:N            │ 1:1                  │
│                    ▼                ▼                ▼                      │
│             ┌───────────┐   ┌───────────┐   ┌───────────────┐              │
│             │  SERVICO  │   │   PECA    │   │   ORCAMENTO   │              │
│             │───────────│   │───────────│   │───────────────│              │
│             │ id        │   │ id        │   │ id            │              │
│             │ nome      │   │ nome      │   │ os_id         │              │
│             │ valor     │   │ codigo    │   │ valor_total   │              │
│             │ os_id     │   │ valor     │   │ status        │              │
│             └───────────┘   │ estoque   │   │ aprovado_em   │              │
│                             │ os_id     │   └───────────────┘              │
│                             └───────────┘                                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🚀 Passos para Execução e Deploy

### Pré-requisitos

1. [Terraform](https://www.terraform.io/downloads.html) >= 1.0
2. [AWS CLI](https://aws.amazon.com/cli/) configurado
3. **Network já provisionada** (via OficinaPro-DevOps/network)
4. Backend remoto configurado (S3 bucket)

### Variáveis de Ambiente

```bash
export AWS_ACCESS_KEY_ID="sua-access-key"
export AWS_SECRET_ACCESS_KEY="sua-secret-key"
export TF_VAR_db_password="senha-segura-minimo-8-caracteres"
```

### Deploy

```bash
# 1. Inicializar Terraform
terraform init

# 2. Validar configuração
terraform validate

# 3. Planejar mudanças
terraform plan -out=tfplan

# 4. Aplicar mudanças
terraform apply tfplan
```

### Verificar conexão

```bash
# Obter endpoint do RDS
terraform output db_instance_address

# Testar conexão (via EC2 na VPC)
psql -h <endpoint> -U oficinapro_app -d oficinapro
```

## ⚙️ Configurações

### Variáveis Principais

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `aws_region` | Região AWS | `us-east-1` |
| `project_name` | Nome do projeto | `oficinapro` |
| `db_name` | Nome do banco | `oficinapro` |
| `db_username` | Usuário do banco | `oficinapro_app` |
| `db_password` | Senha do banco | (sensível) |

### Especificações RDS

| Configuração | Valor |
|--------------|-------|
| **Engine** | PostgreSQL 15.10 |
| **Instance Class** | db.t3.micro (Free Tier) |
| **Storage** | 20 GB (GP2, expansível até 100GB) |
| **Backup Retention** | 1 dia |
| **Multi-AZ** | Não (Free Tier) |
| **Encryption** | Não (Free Tier) |
| **Public Access** | Não |

## 📊 Outputs

| Output | Descrição |
|--------|-----------|
| `db_instance_address` | Endpoint do RDS |
| `db_instance_name` | Nome do banco |
| `db_instance_username` | Usuário do banco |
| `db_security_group_id` | ID do Security Group |

## 🔐 Segurança

- **Acesso Restrito**: Apenas recursos dentro da VPC podem acessar o RDS
- **Sem acesso público**: `publicly_accessible = false`
- **Security Group**: Porta 5432 liberada apenas para CIDR da VPC
- **Senhas**: Gerenciadas via variáveis de ambiente (não commitadas)
- **Backup**: Retention de 1 dia automático

## 🔄 Integração com Outros Serviços

### Core Domain Service (Java/Spring Boot)
```yaml
# application.properties
spring.datasource.url=jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}
```

### Auth Gateway (Go)
```go
dsn := fmt.Sprintf("host=%s port=5432 user=%s password=%s dbname=%s sslmode=disable",
    os.Getenv("DB_HOST"),
    os.Getenv("DB_USER"),
    os.Getenv("DB_PASSWORD"),
    os.Getenv("DB_NAME"))
```

## 📚 Documentação Relacionada

| Documento | Descrição |
|-----------|-----------|
| [DevOps](../OficinaPro-DevOps/README.md) | Infraestrutura geral |
| [Core Service](../core-domain-service/README.md) | Aplicação principal |
| [Auth Service](../auth-oficinapro/README.md) | Serviço de autenticação |

## 💰 Custos

| Recurso | Free Tier | Após Free Tier |
|---------|-----------|----------------|
| RDS db.t3.micro | 750 horas/mês | ~$12.41/mês |
| Storage (20GB) | 20 GB inclusos | $0.115/GB/mês |
| Backup | Incluído | Incluído |

## 🛠️ Comandos Úteis

```bash
# Destruir infraestrutura
terraform destroy

# Ver estado atual
terraform state list

# Importar recurso existente
terraform import aws_db_instance.budget_db <identifier>

# Atualizar apenas um recurso
terraform apply -target=aws_db_instance.budget_db
```

## 👥 Equipe

Desenvolvido para o **Tech Challenge da FIAP**.

---

**Status**: ✅ Produção Ready
**Engine**: PostgreSQL 15.10
**Última atualização**: Janeiro de 2026

