resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.subnet_ids

  tags = {
    Environment = var.environment
    Project     = "tasktracker"
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db-sg"
  description = "Postgres access for ${var.name_prefix} (dev)"
  vpc_id      = var.vpc_id

  # Temporary dev access rule.
  # We will tighten this later when EC2 app connectivity is in place.
#   ingress {
#     description = "Postgres from anywhere (temporary dev)"
#     from_port   = 5432
#     to_port     = 5432
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

  # Safer version to use later instead of the temporary rule above:
  # ingress {
  #   description = "Postgres"
  #   from_port   = 5432
  #   to_port     = 5432
  #   protocol    = "tcp"
  #   cidr_blocks = [var.allowed_cidr]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Project     = "tasktracker"
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_db_instance" "this_standard" {
  count = var.use_managed_master_password ? 0 : 1

  identifier = "${var.name_prefix}-postgres"

  engine         = "postgres"
  engine_version = "17"

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage_gb
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  multi_az            = var.multi_az
  publicly_accessible = true

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true
  apply_immediately       = true

  tags = {
    Environment = var.environment
    Project     = "tasktracker"
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_db_instance" "this_managed" {
  count = var.use_managed_master_password ? 1 : 0

  identifier = "${var.name_prefix}-postgres"

  engine         = "postgres"
  engine_version = "17"

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage_gb
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  multi_az            = var.multi_az
  publicly_accessible = false

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true
  apply_immediately       = true

  tags = {
    Environment = var.environment
    Project     = "tasktracker"
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}