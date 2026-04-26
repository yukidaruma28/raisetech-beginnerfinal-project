resource "aws_security_group" "ec2" {
  name        = "${var.project}-ec2-sg"
  description = "Allow HTTP(8080) from anywhere; all outbound"
  vpc_id      = aws_vpc.main.id

  # ポート 8080 = nginx (フロント配信 + /api/* をバックエンドへリバースプロキシ)。
  # SSH(22) は開けない。EC2 には SSM Session Manager でアクセスする。
  ingress {
    description = "HTTP 8080 from anywhere"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  # 外向き通信は全許可 (ECR pull / SSM / OS アップデート等で必要)
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-ec2-sg"
  }
}

# RDS 用セキュリティグループ: EC2 SG からのみ 3306 を許可。
resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "Allow MySQL from EC2 SG only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from EC2 SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-rds-sg"
  }
}
