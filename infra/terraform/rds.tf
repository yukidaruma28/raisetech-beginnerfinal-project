resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_c.id]

  tags = {
    Name = "${var.project}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project}-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  # ストレージ (無料枠 20GB に収める)
  allocated_storage     = 20
  max_allocated_storage = 0
  storage_type          = "gp3"
  storage_encrypted     = true

  # DB 初期化
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # ネットワーク (Private サブネット + EC2 SG のみ)
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # 可用性 (無料枠内)
  multi_az = false

  # バックアップ
  backup_retention_period = 1
  backup_window           = "17:00-18:00"

  # メンテナンス
  maintenance_window         = "Mon:18:00-Mon:19:00"
  auto_minor_version_upgrade = true

  # 削除関連 (学習用なので気軽に destroy できるように)
  skip_final_snapshot = true
  deletion_protection = false

  performance_insights_enabled = false

  tags = {
    Name = "${var.project}-db"
  }
}
