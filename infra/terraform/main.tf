provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project = var.project
    }
  }
}

# 既存 EC2 インスタンスの参照（デプロイ先）
data "aws_instance" "ec2" {
  instance_id = var.ec2_instance_id
}
