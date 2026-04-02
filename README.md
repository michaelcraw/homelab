# Fleet Management Homelab

A 7-machine homelab fleet managed remotely from a MacBook, featuring Kubernetes (k3s), Docker, Grafana/Prometheus monitoring, self-hosted AI, a WAN-accessible NAS, live camera system, SSH honeypot, and automated fleet management — all connected via Tailscale mesh VPN.

## Network Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Tailscale Mesh VPN                          │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  MacBook Pro │  │  Dell 7050   │  │     Sony VAIO        │   │
│  │  M1 (daily   │  │  i7-6700     │  │  Core2 Duo           │   │
│  │  driver)     │  │  32GB RAM    │  │  4GB RAM             │   │
│  │              │  │              │  │                      │   │
│  │  • Command   │  │  • K8s       │  │  • Grafana           │   │
│  │    Center    │  │    Control   │  │  • Prometheus        │   │
│  │  • Syncthing │  │    Plane     │  │  • WOL Relay         │   │
│  │  • Fleet     │  │  • Ollama    │  │  • Always On         │   │
│  │    Scripts   │  │  • Open      │  │                      │   │
│  │  • Node      │  │    WebUI     │  │                      │   │
│  │    Exporter  │  │  • Docker    │  │                      │   │
│  │              │  │  • Cowrie    │  │                      │   │
│  │              │  │  • Nginx     │  │                      │   │
│  │              │  │  • Funnel    │  │                      │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  HP Compaq   │  │   Lenovo     │  │   Raspberry Pi 4     │   │
│  │  AMD A10     │  │              │  │                      │   │
│  │  19GB RAM    │  │  • K8s       │  │  • Live Camera       │   │
│  │              │  │    Worker    │  │    (Motion)          │   │
│  │  • K8s Worker│  │  • Sysadmin  │  │  • Auto Storage      │   │
│  │  • WAN NAS   │  │    Sandbox   │  │    Rotation          │   │
│  │  • Samba     │  │              │  │                      │   │
│  │  • Syncthing │  │              │  │                      │   │
│  │  • mergerfs  │  │              │  │                      │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
│                                                                 │
│  ┌──────────────┐                                               │
│  │  Dell 5070   │                                               │
│  │  Linux Mint  │                                               │
│  │              │                                               │
│  │  • Syncthing │                                               │
│  │  • Secondary │                                               │
│  │    Desktop   │                                               │
│  └──────────────┘                                               │
└─────────────────────────────────────────────────────────────────┘
```

## Fleet Overview

| Machine | OS | CPU | RAM | Storage | Tailscale IP | Role |
|---------|------|-----|-----|---------|-------------|------|
| MacBook Pro M1 | macOS | Apple M1 | 8GB | 512GB SSD | 100.112.165.19 | Daily driver, command center |
| Dell 7050 | Debian 13 | i7-6700 (4c/8t) | 32GB | 465GB HDD | 100.117.229.28 | K8s control plane, Docker, Ollama, video hosting |
| Sony VAIO | Debian 13 | Core2 Duo T6600 | 4GB | 128GB SSD | 100.96.120.65 | Monitoring (Grafana/Prometheus), WOL relay |
| HP Compaq | Debian 12 | AMD A10-5800K | 19GB | 256GB SSD + 1TB HDD + 500GB HDD | 100.64.249.4 | K8s worker, WAN NAS, Syncthing |
| Lenovo | Debian 13 | Intel Core M | 8GB | 256GB SSD | 100.66.222.35 | K8s worker, sysadmin playground |
| Raspberry Pi 4 | Debian 13 | ARM Cortex-A72 | 4GB | 32GB SD + 2x USB drives | 100.73.143.19 | Live camera (Motion) |
| Dell 5070 | Linux Mint | i7-9700T | 32GB | NVMe SSD | 100.108.102.105 | Secondary desktop, Syncthing |

## What's Running

### Kubernetes (k3s) — 3-Node Cluster
- **Control plane + worker:** Dell 7050
- **Worker nodes:** HP Compaq, Lenovo
- Automatic pod scheduling and self-healing across nodes

### Monitoring Stack (Sony VAIO)
- **Prometheus** scraping Node Exporter and smartctl_exporter from all machines
- **Grafana** dashboards for CPU, RAM, disk, network, SMART health, and CPU temperature
- **Alerting** via Slack webhooks for:
  - CPU temperature above 176°F (80°C)
  - Machine offline
  - Disk health degradation (reallocated sectors)
  - Disk space above 85%
  - RAM usage above 90%

### WAN NAS (HP Compaq)
- Built from scratch on a bare HP Compaq Pro 6305
- WiFi driver (RTL88x2BU) compiled from source with DKMS for auto-rebuild on kernel updates
- Debian 12 installed offline using DVD ISO as local apt repository
- Two drives (1TB HGST + 500GB Seagate) formatted ext4 and merged via **mergerfs**
- **Samba** file sharing with multi-user access (michael + corrin)
- **Syncthing** Docker container auto-syncing Mac, Dell 5070, and NAS

### Self-Hosted AI (Dell 7050)
- **Ollama** running llama3.2, gemma3:12b, and deepseek-r1:14b models
- **Open WebUI** providing a ChatGPT-like interface accessible on the tailnet
- CPU-only inference on i7-6700

### Video Hosting (Dell 7050)
- **Nginx** Docker container serving a homelab project video
- Publicly accessible via **Tailscale Funnel** with a QR code for sharing

### Live Camera (Raspberry Pi 4)
- **Motion** software capturing 640x480 at 15fps from USB webcam
- Live stream accessible on port 8081 via Tailscale
- 60-second MKV clip recording with automated storage rotation
- Custom **systemd timer** checks disk usage every 5 minutes and switches recording to a secondary USB drive at 90% capacity

### SSH Honeypot (Dell 7050)
- **Cowrie** SSH honeypot running in Docker on port 2222
- Logs all connection attempts, credentials, and commands
- Internal use for security research and learning

### Fleet Automation (Mac)
- **update-fleet.sh** — runs apt update/upgrade on all machines
- **reboot-fleet.sh** — reboots selected machines remotely
- **shutdown-fleet.sh** — shuts down the fleet
- **dellHpOff.sh** — targeted shutdown for Dell + HP
- **wake-fleet.sh** / **wake-dellHp.sh** — Wake-on-LAN via Sony relay
- All scripts handle offline machines gracefully

### Wake-on-LAN
- WOL enabled in BIOS and OS (ethtool + systemd service) on Dell 7050 and HP Compaq
- Sony VAIO acts as always-on relay — Mac SSHs into Sony over Tailscale, Sony sends magic packets on the local LAN
- Required disabling Deep Sleep on Dell 7050 BIOS

### File Synchronization
- **Syncthing** syncs school, aws, job, and random folders across Mac ↔ HP NAS ↔ Dell 5070
- HP NAS acts as always-on hub — machines sync when they come online
- Accessible via Samba from any machine on the tailnet

## Networking
- All machines connected via **Tailscale** mesh VPN (WireGuard-based)
- SSH key authentication across the fleet with passwordless sudo for automation
- Local ethernet for performance-critical connections (NAS transfers ~30MB/s local vs ~5MB/s over Tailscale)
- UFW firewall on all Linux machines

## Backups
- Sony VAIO config tarball backed up to HP NAS (`/mnt/nas/michael/sony-backup.tar.gz`)
- Full Sony disk clone stored on Mac (`~/sony-disk-clone.gz`)
- Syncthing provides automatic file backup across three machines

## Project Structure

```
homelab/
├── README.md
├── scripts/
│   ├── update-fleet.sh          # Fleet-wide apt update/upgrade
│   ├── reboot-fleet.sh          # Fleet reboot with Pi prompt
│   ├── shutdown-fleet.sh        # Fleet shutdown
│   ├── dellHpOff.sh             # Targeted Dell + HP shutdown
│   ├── wake-fleet.sh            # WOL wake all machines
│   ├── wake-dellHp.sh           # WOL wake Dell + HP
│   └── motion-storage-check.sh  # Pi camera storage rotation
├── configs/
│   ├── prometheus/
│   │   └── prometheus.yml       # Prometheus scrape configuration
│   ├── grafana/                 # Grafana dashboard exports
│   ├── samba/                   # Samba share configuration
│   └── syncthing/               # Syncthing configuration
└── screenshots/                 # Grafana dashboard screenshots
```

## Skills & Technologies

- **Infrastructure:** Kubernetes (k3s), Docker, Tailscale, Nginx, Samba, mergerfs
- **Monitoring:** Prometheus, Grafana, Node Exporter, smartctl_exporter, Slack alerting
- **AI/ML:** Ollama, Open WebUI, LLM inference
- **Security:** Cowrie SSH honeypot, SSH key authentication, UFW, WireGuard
- **Automation:** Bash scripting, systemd services, Wake-on-LAN, DKMS
- **Operating Systems:** Debian 12/13, Linux Mint, macOS
- **Networking:** Layer 2/3, WOL, DNS, SMB, mesh VPN

## Author

**Michael Crawford**  
Computer Science, University of Denver (Expected June 2026)  
AWS Certified Cloud Practitioner

[LinkedIn](https://www.linkedin.com/in/michael-crawford-2a17aa1ab) | [GitHub](https://github.com/michaelcraw)
