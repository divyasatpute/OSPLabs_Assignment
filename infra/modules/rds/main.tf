##############################################
# DB Subnet Group
##############################################

resource "aws_db_subnet_group" "this" {

  name = "${var.project_name}-${var.environment}-subnet-group"

  subnet_ids = var.private_db_subnets

  tags = {
    Name = "${var.project_name}-${var.environment}-subnet-group"
  }

}

##############################################
# PostgreSQL Database
##############################################

resource "aws_db_instance" "this" {

  identifier = "${var.project_name}-${var.environment}-postgres"

  engine = "postgres"

  engine_version = "16.3"

  instance_class = var.instance_class

  allocated_storage = var.allocated_storage

  storage_type = "gp3"

  db_name = var.db_name

  username = var.db_username

  password = var.db_password

  port = 5432

  db_subnet_group_name = aws_db_subnet_group.this.name

  vpc_security_group_ids = [
    var.rds_security_group
  ]

  publicly_accessible = false

  multi_az = true

  backup_retention_period = var.backup_retention_period

  deletion_protection = var.deletion_protection

  skip_final_snapshot = !var.deletion_protection

  apply_immediately = true

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
  }

}
