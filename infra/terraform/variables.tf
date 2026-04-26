variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_profile" {
  description = "AWS CLIプロファイル名"
  type        = string
  default     = "kanban"
}

variable "project" {
  description = "プロジェクト名（リソース命名プレフィックス）"
  type        = string
  default     = "kanban-linear"
}

# --- 既存インフラの参照 ---

variable "vpc_id" {
  description = "既存 VPC の ID（raiseTech_AI と共用）"
  type        = string
  default     = "vpc-074caa239f81ddc22"
}

variable "private_subnet_1a_id" {
  description = "既存 Private Subnet 1a の ID"
  type        = string
  default     = "subnet-072b597b6778bb324"
}

variable "private_subnet_1c_id" {
  description = "既存 Private Subnet 1c の ID"
  type        = string
  default     = "subnet-0641ecb926efc34be"
}

variable "ec2_sg_id" {
  description = "既存 EC2 Security Group の ID"
  type        = string
  default     = "sg-0b0fce23d43f06913"
}

variable "ec2_instance_id" {
  description = "既存 EC2 インスタンス ID"
  type        = string
  default     = "i-031ce57e84c26ca37"
}

# --- RDS (MySQL) ---

variable "db_instance_class" {
  description = "RDS インスタンスクラス"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "作成する MySQL データベース名"
  type        = string
  default     = "inquiry_tracker_production"
}

variable "db_username" {
  description = "RDS マスターユーザー名"
  type        = string
  default     = "inquiry"
}

variable "db_password" {
  description = "RDS マスターパスワード（terraform.tfvars で指定）"
  type        = string
  sensitive   = true
}
