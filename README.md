# Homelab Dashboard

A Docker-free Proxmox LXC dashboard for Proxmox VE, TrueNAS, LXC containers, VMs, service health checks, and network topology.

## Install

Run from your Proxmox host shell:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Agurri/homelab-dashboard/main/ct/HomelabDashboard.sh)"
```

Optional overrides:

```bash
var_cpu=2 var_ram=2048 var_disk=15 DASHBOARD_VERSION=v1.0.0 \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Agurri/homelab-dashboard/main/ct/HomelabDashboard.sh)"
```

## After installation

Edit the environment file:

```bash
nano /opt/homelab-dashboard/shared/.env
systemctl restart homelab-dashboard
```

Then open:

```text
http://<LXC-IP>:3000
```

## Update

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Agurri/homelab-dashboard/main/tools/homelabdashboard-update.sh)" -- v1.1.0
```

## Layout

```text
/opt/homelab-dashboard/
├── releases/
├── current -> releases/v1.0.0
├── shared/
│   ├── .env
│   ├── config/
│   └── data/
└── backups/
```

## Services

```bash
systemctl status homelab-dashboard
journalctl -u homelab-dashboard -f
```
