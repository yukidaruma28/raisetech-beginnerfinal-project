# MySQL RDS 専用 Security Group
# EC2 SG からの MySQL (3306) のみ許可
resource "aws_security_group" "rds_mysql" {
  name        = "${var.project}-rds-sg"
  description = "MySQL RDS for ${var.project}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ec2_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-rds-sg"
  }
}
