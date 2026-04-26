#!/bin/bash
set -eu
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "[user_data] start"

# 1. Swap 2GB (t3.micro の 1GB RAM を補う)
if [ ! -f /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# 2. Docker + git インストール
dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ec2-user

# 3. Docker Compose v2 (plugin)
mkdir -p /usr/local/lib/docker/cli-plugins
curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# 4. アプリ用ディレクトリ作成
mkdir -p /opt/kanban-linear

# 5. systemd サービス登録 (deploy.sh で初回デプロイ後、reboot 時の自動起動に使用)
cat > /etc/systemd/system/kanban-linear.service <<'UNIT'
[Unit]
Description=kanban-linear app (docker compose)
After=docker.service network-online.target
Requires=docker.service
Wants=network-online.target

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

echo "[user_data] done"
