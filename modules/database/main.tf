resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "tennis-db-subnet-group"
  subnet_ids = var.db_subnet_ids
}

resource "aws_db_instance" "postgres" {
  identifier            = "tennis-postgres-free-tier"
  engine                = "postgres"
  engine_version        = "18.3"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"

  db_name                = "tennis_league"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = var.db_security_group_ids
  skip_final_snapshot    = true

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  copy_tags_to_snapshot   = true

  auto_minor_version_upgrade = true
  maintenance_window         = "Mon:04:00-Mon:05:00"

  lifecycle {
    ignore_changes = [engine_version]
  }

  tags = { Name = "tennis-postgres-instance" }
}
