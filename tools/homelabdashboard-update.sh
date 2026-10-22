#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/homelab-dashboard"
VERSION="${1:?Usage: homelabdashboard-update.sh v1.1.0}"
RELEASE="$APP_DIR/releases/$VERSION"
SERVICE="homelab-dashboard"
REPO_URL="${DASHBOARD_REPO:-https://github.com/Agurri/homelab-dashboard.git}"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root."
  exit 1
fi

msg_info "Backing up dashboard data"
tar -czf "$APP_DIR/backups/pre-$VERSION-$(date +%F-%H%M).tar.gz" \
  -C "$APP_DIR/shared" .env config data
msg_ok "Backup complete"

msg_info "Downloading $VERSION"
sudo -u dashboard git clone --depth 1 --branch "$VERSION" "$REPO_URL" "$RELEASE"
msg_ok "Downloaded $VERSION"

msg_info "Installing dependencies"
cd "$RELEASE"
sudo -u dashboard ln -sfn "$APP_DIR/shared/.env" .env
sudo -u dashboard ln -sfn "$APP_DIR/shared/config" config
sudo -u dashboard ln -sfn "$APP_DIR/shared/data" data
sudo -u dashboard npm ci --omit=dev
sudo -u dashboard npm run migrate --if-present
msg_ok "Dependencies installed"

msg_info "Activating $VERSION"
ln -sfn "$RELEASE" "$APP_DIR/current"
systemctl restart "$SERVICE"
msg_ok "Activated $VERSION"

msg_info "Checking service"
if systemctl is-active --quiet "$SERVICE"; then
  msg_ok "Homelab Dashboard updated successfully"
else
  msg_error "Service failed after update"
  journalctl -u "$SERVICE" -n 50 --no-pager
  exit 1
fi
