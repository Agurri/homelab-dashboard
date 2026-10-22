#!/usr/bin/env bash

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)

APP="homelab-dashboard"
APP_DIR="/opt/homelab-dashboard"
SERVICE_USER="dashboard"
SERVICE_NAME="homelab-dashboard"

BRANCH="${DASHBOARD_BRANCH:-main}"
REPO_URL="${DASHBOARD_REPO:-https://github.com/Agurri/homelab-dashboard.git}"
PORT="${DASHBOARD_PORT:-3000}"
RELEASE_DIR="$APP_DIR/releases/$(date +%Y%m%d%H%M%S)"
CURRENT_LINK="$APP_DIR/current"

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt-get install -y curl ca-certificates git gnupg
curl -fsSL https://deb.nodesource.com/setup_22.x -o /tmp/nodesource_setup.sh
$STD bash /tmp/nodesource_setup.sh
$STD apt-get install -y nodejs
msg_ok "Installed dependencies"

msg_info "Creating service user and directories"
if ! id "$SERVICE_USER" &>/dev/null; then
  useradd --system --home "$APP_DIR" --shell /usr/sbin/nologin "$SERVICE_USER"
fi

mkdir -p \
  "$APP_DIR/releases" \
  "$APP_DIR/shared/config" \
  "$APP_DIR/shared/data" \
  "$APP_DIR/backups" \
  "$APP_DIR/scripts"

chown -R "$SERVICE_USER:$SERVICE_USER" "$APP_DIR"
msg_ok "Created service user and directories"

msg_info "Downloading Homelab Dashboard from $BRANCH"
sudo -u "$SERVICE_USER" git clone --depth 1 --branch "$BRANCH" \
  "$REPO_URL" "$RELEASE_DIR"
msg_ok "Downloaded Homelab Dashboard"

msg_info "Configuring Homelab Dashboard"
sudo -u "$SERVICE_USER" bash <<EOF
set -euo pipefail
cd "$RELEASE_DIR"

ln -sfn "$APP_DIR/shared/.env" .env
ln -sfn "$APP_DIR/shared/config" config
ln -sfn "$APP_DIR/shared/data" data

if [[ ! -f "$APP_DIR/shared/.env" ]]; then
  cat > "$APP_DIR/shared/.env" <<'ENV'
NODE_ENV=production
PORT=3000
PVE_URL=https://192.168.1.10:8006
PVE_TOKEN_ID=dashboard@pam!homelab-dashboard
PVE_TOKEN_SECRET=change-me
TRUENAS_URL=wss://192.168.1.20/websocket
TRUENAS_API_KEY=change-me
REFRESH_SECONDS=15
ENV
fi

npm install --omit=dev
npm run migrate
EOF

chmod 600 "$APP_DIR/shared/.env"
chown "$SERVICE_USER:$SERVICE_USER" "$APP_DIR/shared/.env"
ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"
msg_ok "Configured Homelab Dashboard"

msg_info "Creating systemd service"
cat >"/etc/systemd/system/$SERVICE_NAME.service" <<EOF
[Unit]
Description=Homelab Control Center
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$CURRENT_LINK
EnvironmentFile=$APP_DIR/shared/.env
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR/shared/data

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable -q --now "$SERVICE_NAME"
msg_ok "Created systemd service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned up"

IP=$(hostname -I | awk '{print $1}')
echo
echo -e "${TAB}Homelab Dashboard is running at:${CL}"
echo -e "${TAB}${BL}http://$IP:$PORT${CL}"
