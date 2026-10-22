#!/usr/bin/env bash

# Copyright (c) 2026 Olivier
# License: MIT

APP="HomelabDashboard"
var_tags="dashboard;monitoring;proxmox;truenas"
var_cpu="2"
var_ram="2048"
var_disk="10"
var_os="debian"
var_version="12"
var_unprivileged="1"

export DASHBOARD_VERSION="${DASHBOARD_VERSION:-v1.0.0}"
export DASHBOARD_REPO="${DASHBOARD_REPO:-https://github.com/Agurri/homelab-dashboard.git}"
export DASHBOARD_PORT="${DASHBOARD_PORT:-3000}"

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

function update_script() {
  msg_info "Updating ${APP}"
  lxc-attach -n "$CTID" -- bash -c "$(curl -fsSL https://raw.githubusercontent.com/Agurri/homelab-dashboard/main/tools/homelabdashboard-update.sh)"
  msg_ok "Updated ${APP}"
}

start
build_container
description

msg_info "Starting ${APP}"
lxc-start -n "$CTID"
sleep 5
msg_ok "Started ${APP}"

lxc-attach -n "$CTID" -- bash -c "$(curl -fsSL https://raw.githubusercontent.com/Agurri/homelab-dashboard/main/install/homelabdashboard-install.sh)"

IP=$(pct exec "$CTID" -- hostname -I | awk '{print $1}')

echo
echo -e "${DGN}Homelab Dashboard installed successfully.${CL}"
echo -e "${DGN}URL: ${BL}http://$IP:${DASHBOARD_PORT}${CL}"
echo -e "${DGN}Configuration: ${BL}/opt/homelab-dashboard/shared/.env${CL}"
