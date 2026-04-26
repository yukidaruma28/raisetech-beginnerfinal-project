#!/usr/bin/env bash
# 既存 EC2 への初回セットアップ（一度だけ実行）
# Docker + Docker Compose v2 + systemd サービスを設定する
# Usage: bash infra/ec2-setup.sh
set -euo pipefail

PROFILE="${AWS_PROFILE:-kanban}"
REGION="${AWS_REGION:-ap-northeast-1}"
INSTANCE_ID="${INSTANCE_ID:-i-031ce57e84c26ca37}"

echo "=== EC2 初回セットアップ (SSM) ==="

CMD_B64=$(base64 -w 0 << 'SETUP_SCRIPT'
#!/bin/bash
set -eu

# Docker（未インストールなら追加）
if ! command -v docker &>/dev/null; then
  dnf install -y docker
  systemctl enable --now docker
  usermod -aG docker ec2-user
fi

# Docker Compose v2 plugin
if ! docker compose version &>/dev/null 2>&1; then
  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -fsSL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi

mkdir -p /opt/kanban-linear

# systemd サービス（deploy.sh が docker compose up を呼ぶので Restart=on-failure のみ）
cat > /etc/systemd/system/kanban-linear.service << 'UNIT'
[Unit]
Description=Kanban Linear app (docker compose)
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/kanban-linear
ExecStart=/usr/bin/docker compose -f infra/docker-compose.prod.yml --env-file .env up -d
ExecStop=/usr/bin/docker compose -f infra/docker-compose.prod.yml down
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable kanban-linear

echo "=== セットアップ完了 ==="
SETUP_SCRIPT
)

CMD_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters "$(jq -n --arg cmd "echo $CMD_B64 | base64 -d | bash" '{"commands":[$cmd]}')" \
  --profile "$PROFILE" --region "$REGION" \
  --output text --query 'Command.CommandId')

echo "CommandId: $CMD_ID (待機中...)"
aws ssm wait command-executed \
  --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" \
  --profile "$PROFILE" --region "$REGION" 2>/dev/null || true

aws ssm get-command-invocation \
  --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" \
  --profile "$PROFILE" --region "$REGION" \
  --query 'StandardOutputContent' --output text

echo ""
echo "次: bash deploy.sh"
