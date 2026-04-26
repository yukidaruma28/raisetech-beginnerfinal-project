variable "aws_region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_profile" {
  description = "AWS CLI プロファイル名"
  type        = string
  default     = "kanban"
}

variable "project" {
  description = "リソース命名のプレフィックス"
  type        = string
  default     = "kanban-linear"
}

variable "vpc_cidr" {
  description = "VPC の CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public サブネットの CIDR (EC2 用)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_a_cidr" {
  description = "Private サブネット A (ap-northeast-1a) の CIDR。RDS 用"
  type        = string
  default     = "10.0.10.0/24"
}

variable "private_subnet_c_cidr" {
  description = "Private サブネット C (ap-northeast-1c) の CIDR。RDS 用"
  type        = string
  default     = "10.0.11.0/24"
}

variable "ec2_instance_type" {
  description = "EC2 インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ingress_cidrs" {
  description = "EC2 への HTTP(8080) アクセスを許可する CIDR 一覧。ポートフォリオ公開なら [\"0.0.0.0/0\"]"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ---------- RDS ----------

variable "db_instance_class" {
  description = "RDS インスタンスクラス"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "データベース名"
  type        = string
  default     = "inquiry_tracker_production"
}

variable "db_username" {
  description = "RDS マスターユーザー名"
  type        = string
  default     = "inquiry"
}

variable "db_password" {
  description = "RDS マスターパスワード (terraform.tfvars で指定。コミットしないこと)"
  type        = string
  sensitive   = true
}
