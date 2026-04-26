data "aws_caller_identity" "current" {}

output "ec2_public_ip" {
  description = "EC2 の Elastic IP"
  value       = aws_eip.app.public_ip
}

output "ec2_instance_id" {
  description = "EC2 インスタンス ID (SSM 接続・deploy.sh 用)"
  value       = aws_instance.app.id
}

output "ecr_registry" {
  description = "ECR レジストリ URL (docker login 用)"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "ecr_backend_url" {
  description = "ECR backend リポジトリ URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_url" {
  description = "ECR frontend リポジトリ URL"
  value       = aws_ecr_repository.frontend.repository_url
}

output "app_url" {
  description = "ブラウザでアクセスする URL"
  value       = "http://${aws_eip.app.public_ip}:8080/"
}

output "rds_endpoint" {
  description = "RDS のエンドポイント (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "rds_host" {
  description = "RDS のホスト名 (deploy.sh 用)"
  value       = aws_db_instance.main.address
}
