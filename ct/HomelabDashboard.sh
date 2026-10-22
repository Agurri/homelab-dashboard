#!/usr/bin/env bash

APP="HomelabDashboard"
var_tags="dashboard;monitoring;proxmox;truenas"
var_cpu="2"
var_ram="2048"
var_disk="10"
var_os="debian"
var_version="12"
var_unprivileged="1"

export DASHBOARD_BRANCH="${DASHBOARD_BRANCH:-main}"
export DASHBOARD_REPO="${DASHBOARD_REPO:-https://github.com/Agurri/homelab-dashboard.git}"
export DASHBOARD_PORT="${DASHBOARD_PORT:-3000}"

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

header_info "$APP"
base_settings
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  CT_DISK_SIZE="$var_disk"
  CT_CORES="$var_cpu"
  CT_MEMORY="$var_ram"
  CT_HOSTNAME="homelab-dashboard"
  CT_BRIDGE="vmbr0"
  CT_NETMASK="24"
  CT_DHCP="1"
}

start
build_container
description

msg_info "Starting Homelab Dashboard"
lxc-start -n "$CTID"
sleep 5
msg_ok "Started Homelab Dashboard"

lxc-attach -n "$CTID" -- bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/Agurri/homelab-dashboard/main/install/homelabdashboard-install.sh)"

IP=$(pct exec "$CTID" -- hostname -I | awk '{print $1}')

echo
echo -e "${DGN}Homelab Dashboard installed successfully.${CL}"
echo -e "${DGN}URL: ${BL}http://$IP:${DASHBOARD_PORT}${CL}"
echo -e "${DGN}Configuration: ${BL}/opt/homelab-dashboard/shared/.env${CL}"
