resource "random_password" "db" {
  length  = 32
  special = false # avoid shell-escaping issues when passed via env vars
}

# Store the password in SSM so the deploy pipeline can inject it into K8s Secrets
# without it appearing in Terraform outputs or CI logs.
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/db/password"
  type  = "SecureString"
  value = random_password.db.result
  tags  = var.tags
}

resource "aws_db_subnet_group" "this" {
  name       = var.cluster_name
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

# Only EKS nodes can reach the database — no public access, no broad VPC CIDR rule.
resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds"
  description = "Allow PostgreSQL access from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_db_instance" "this" {
  identifier     = var.cluster_name
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = false
  publicly_accessible = false

  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = var.tags
}
