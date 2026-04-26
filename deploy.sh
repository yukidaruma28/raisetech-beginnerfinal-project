#!/usr/bin/env bash
# Usage:
#   EC2_HOST=1.2.3.4 \
#   SSH_KEY=~/.ssh/your-key.pem \
#   DB_HOST=xxxx.rds.amazonaws.com \
#   DB_USERNAME=admin \
#   DB_PASSWORD=yourpassword \
#   ./deploy.sh
set -euo pipefail

: "${EC2_HOST:?EC2_HOST is required}"
: "${SSH_KEY:?SSH_KEY is required}"
: "${DB_HOST:?DB_HOST is required}"
: "${DB_USERNAME:?DB_USERNAME is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"

BACKEND_PORT="${BACKEND_PORT:-3001}"
FRONTEND_PORT="${FRONTEND_PORT:-3000}"
APP_DIR="${APP_DIR:-/home/ec2-user/app}"
REPO_URL="https://github.com/yukidaruma28/raisetech-beginnerfinal-project.git"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTER_KEY_FILE="$SCRIPT_DIR/backend/config/master.key"

if [ ! -f "$MASTER_KEY_FILE" ]; then
  echo "ERROR: backend/config/master.key not found"
  exit 1
fi
RAILS_MASTER_KEY=$(cat "$MASTER_KEY_FILE")

ALLOWED_ORIGINS="http://${EC2_HOST}:${FRONTEND_PORT}"
NUXT_PUBLIC_API_BASE_URL="http://${EC2_HOST}:${BACKEND_PORT}"

SSH_OPT="-i $SSH_KEY -o StrictHostKeyChecking=no"
SSH="ssh $SSH_OPT ec2-user@$EC2_HOST"

echo "=== Deploying to $EC2_HOST ==="

echo "--- Step 1: Install Docker + clone repo ---"
$SSH bash << REMOTE
set -euo pipefail

if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  sudo dnf install -y docker git
  sudo systemctl enable --now docker
  sudo usermod -aG docker ec2-user
fi

if [ -d "$APP_DIR/.git" ]; then
  echo "Pulling latest code..."
  cd "$APP_DIR" && git pull origin main
else
  echo "Cloning repo..."
  git clone $REPO_URL "$APP_DIR"
fi
REMOTE

echo "--- Step 2: Copy master.key ---"
scp $SSH_OPT "$MASTER_KEY_FILE" "ec2-user@$EC2_HOST:$APP_DIR/backend/config/master.key"

echo "--- Step 3: Build and start backend ---"
$SSH bash << REMOTE
set -euo pipefail
cd "$APP_DIR"

echo "Building backend image..."
sudo docker build -t kanban-backend ./backend

sudo docker stop kanban-backend 2>/dev/null || true
sudo docker rm   kanban-backend 2>/dev/null || true

sudo docker run -d \
  --name kanban-backend \
  --restart unless-stopped \
  -p $BACKEND_PORT:80 \
  -e RAILS_ENV=production \
  -e RAILS_MASTER_KEY="$RAILS_MASTER_KEY" \
  -e DB_HOST="$DB_HOST" \
  -e DB_PORT=3306 \
  -e DB_USERNAME="$DB_USERNAME" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e ALLOWED_ORIGINS="$ALLOWED_ORIGINS" \
  -e SOLID_QUEUE_IN_PUMA=true \
  kanban-backend

echo "Waiting for backend to start..."
sleep 10

echo "Running db:prepare and db:seed..."
sudo docker exec kanban-backend bin/rails db:prepare
sudo docker exec kanban-backend bin/rails db:seed
REMOTE

echo "--- Step 4: Build and start frontend ---"
$SSH bash << REMOTE
set -euo pipefail
cd "$APP_DIR"

echo "Building frontend image..."
sudo docker build -t kanban-frontend ./frontend

sudo docker stop kanban-frontend 2>/dev/null || true
sudo docker rm   kanban-frontend 2>/dev/null || true

sudo docker run -d \
  --name kanban-frontend \
  --restart unless-stopped \
  -p $FRONTEND_PORT:3000 \
  -e NUXT_PUBLIC_API_BASE_URL="$NUXT_PUBLIC_API_BASE_URL" \
  kanban-frontend
REMOTE

echo ""
echo "=== Deploy complete! ==="
echo "Frontend : http://$EC2_HOST:$FRONTEND_PORT"
echo "Backend  : http://$EC2_HOST:$BACKEND_PORT/api"
