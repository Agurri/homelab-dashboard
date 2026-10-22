# Homelab Dashboard

Docker-free Proxmox LXC dashboard for Proxmox, TrueNAS, containers, service health, and network topology.

## Install

Run from your Proxmox host:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Agurri/homelab-dashboard/main/ct/HomelabDashboard.sh)"
```

## Configuration

After installation, edit:

```bash
nano /opt/homelab-dashboard/shared/.env
systemctl restart homelab-dashboard
```

## Update

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Agurri/homelab-dashboard/main/tools/homelabdashboard-update.sh)" -- v1.1.0
```
