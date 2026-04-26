#!/usr/bin/env bash
# 本番デプロイスクリプト（ECR + SSM、SSH 不要）
#
# 前提:
#   - AWS CLI が kanban プロファイルで設定済み（aws sts get-caller-identity --profile kanban）
#   - terraform apply 完了済み（infra/terraform/ 参照）
#   - jq インストール済み（winget install jqlang.jq）
#   - Docker Desktop 起動済み
#
# Usage（Git Bash）:
#   DB_USERNAME=inquiry DB_PASSWORD=yourpassword bash deploy.sh
set -euo pipefail

PROFILE="${AWS_PROFILE:-kanban}"
REGION="${AWS_REGION:-ap-northeast-1}"
INSTANCE_ID="${INSTANCE_ID:-i-031ce57e84c26ca37}"
REPO_URL="https://github.com/yukidaruma28/raisetech-beginnerfinal-project.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

: "${DB_USERNAME:?DB_USERNAME env var is required}"
: "${DB_PASSWORD:?DB_PASSWORD env var is required}"

# ---------- Terraform 出力から値を取得 ----------
echo "=== Terraform 出力取得 ==="
TF_DIR="$SCRIPT_DIR/infra/terraform"
ECR_REGISTRY=$(terraform -chdir="$TF_DIR" output -raw ecr_registry)
ECR_BACKEND_URL=$(terraform -chdir="$TF_DIR" output -raw ecr_backend_url)
ECR_FRONTEND_URL=$(terraform -chdir="$TF_DIR" output -raw ecr_frontend_url)
DB_HOST=$(terraform -chdir="$TF_DIR" output -raw rds_host)
EC2_IP=$(terraform -chdir="$TF_DIR" output -raw ec2_public_ip)
RAILS_MASTER_KEY=$(cat "$SCRIPT_DIR/backend/config/master.key")

echo "  ECR:    $ECR_REGISTRY"
echo "  DB:     $DB_HOST"
echo "  EC2:    $EC2_IP"

# ---------- ECR ログイン → ビルド → プッシュ ----------
echo "=== ECR ログイン ==="
aws ecr get-login-password --region "$REGION" --profile "$PROFILE" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo "=== Backend ビルド & push ==="
docker build -t "$ECR_BACKEND_URL:latest" "$SCRIPT_DIR/backend"
docker push "$ECR_BACKEND_URL:latest"

echo "=== Frontend ビルド & push ==="
docker build -t "$ECR_FRONTEND_URL:latest" "$SCRIPT_DIR/frontend"
docker push "$ECR_FRONTEND_URL:latest"

# ---------- SSM ヘルパー（jq で JSON エスケープ） ----------
ssm_exec() {
  local desc="$1"; shift
  echo "--- $desc ---"
  # 複数コマンドを && で結合して 1 つの JSON 文字列に
  local combined
  combined=$(printf '%s && ' "$@" | sed 's/ && $//')
  local params
  params=$(jq -n --arg cmd "$combined" '{"commands":[$cmd]}')
  local cmd_id
  cmd_id=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "$params" \
    --profile "$PROFILE" --region "$REGION" \
    --output text --query 'Command.CommandId')
  echo "  CommandId: $cmd_id"
  aws ssm wait command-executed \
    --command-id "$cmd_id" --instance-id "$INSTANCE_ID" \
    --profile "$PROFILE" --region "$REGION" 2>/dev/null || true
  aws ssm get-command-invocation \
    --command-id "$cmd_id" --instance-id "$INSTANCE_ID" \
    --profile "$PROFILE" --region "$REGION" \
    --query 'StandardOutputContent' --output text
}

# ---------- EC2: リポジトリ clone / pull ----------
ssm_exec "リポジトリ取得" \
  "if [ -d /opt/kanban-linear/.git ]; then cd /opt/kanban-linear && git pull origin main; else git clone $REPO_URL /opt/kanban-linear; fi"

# ---------- EC2: .env ファイル書き込み（base64 で特殊文字を安全に転送） ----------
ENV_B64=$(printf '%s\n' \
  "ECR_BACKEND_URL=$ECR_BACKEND_URL" \
  "ECR_FRONTEND_URL=$ECR_FRONTEND_URL" \
  "RAILS_MASTER_KEY=$RAILS_MASTER_KEY" \
  "DB_HOST=$DB_HOST" \
  "DB_USERNAME=$DB_USERNAME" \
  "DB_PASSWORD=$DB_PASSWORD" \
  "EC2_IP=$EC2_IP" \
  | base64 -w 0)

ssm_exec ".env 書き込み" \
  "echo $ENV_B64 | base64 -d > /opt/kanban-linear/.env" \
  "chmod 600 /opt/kanban-linear/.env"

# ---------- EC2: ECR pull & コンテナ起動 ----------
ssm_exec "ECR pull & docker compose up" \
  "aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY" \
  "cd /opt/kanban-linear && docker compose -f infra/docker-compose.prod.yml --env-file .env pull" \
  "cd /opt/kanban-linear && docker compose -f infra/docker-compose.prod.yml --env-file .env up -d"

# ---------- EC2: DB 初期化（初回は db:prepare + seed、2回目以降は migrate のみ） ----------
echo "=== DB 初期化（起動待機 10 秒）==="
sleep 10
ssm_exec "db:prepare & db:seed" \
  "docker exec \$(docker ps -qf name=kanban-linear-backend-1 2>/dev/null || docker ps -qf ancestor=$ECR_BACKEND_URL) bin/rails db:prepare" \
  "docker exec \$(docker ps -qf name=kanban-linear-backend-1 2>/dev/null || docker ps -qf ancestor=$ECR_BACKEND_URL) bin/rails db:seed"

echo ""
echo "=== デプロイ完了 ==="
echo "  App:     http://$EC2_IP:8080/"
echo "  Backend: http://$EC2_IP:8080/api/statuses"
