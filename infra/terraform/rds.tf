resource "aws_db_subnet_group" "mysql" {
  name       = "${var.project}-subnet-group"
  subnet_ids = [var.private_subnet_1a_id, var.private_subnet_1c_id]

  tags = {
    Name = "${var.project}-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier        = "${var.project}-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  vpc_security_group_ids = [aws_security_group.rds_mysql.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  auto_minor_version_upgrade  = true
  maintenance_window          = "Mon:17:00-Mon:17:30"
  backup_window               = "16:00-16:30"

  tags = {
    Name = "${var.project}-db"
  }
}
