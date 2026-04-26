output "ecr_registry" {
  description = "ECR レジストリ URL（アカウント+リージョン部分）"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "ecr_backend_url" {
  description = "backend ECR リポジトリ URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_url" {
  description = "frontend ECR リポジトリ URL"
  value       = aws_ecr_repository.frontend.repository_url
}

output "rds_endpoint" {
  description = "RDS MySQL エンドポイント（host:port）"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_host" {
  description = "RDS MySQL ホスト名のみ"
  value       = aws_db_instance.mysql.address
}

output "ec2_public_ip" {
  description = "既存 EC2 の Public IP"
  value       = data.aws_instance.ec2.public_ip
}

output "app_url" {
  description = "アプリ URL（EC2 IP + ポート 8080）"
  value       = "http://${data.aws_instance.ec2.public_ip}:8080/"
}

data "aws_caller_identity" "current" {}
