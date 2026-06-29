# Fleet Management Homelab

An 8-machine homelab fleet managed remotely from a MacBook, featuring Kubernetes (k3s), Docker, Grafana/Prometheus monitoring, self-hosted AI, a WAN-accessible NAS, live camera system with motion alerts, a dedicated Grafana kiosk display, and automated fleet management — all connected via Tailscale mesh VPN.

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
│  │  • Command   │  │  • K8s Worker│  │  • Grafana           │   │
│  │    Center    │  │  • Ollama    │  │  • Prometheus        │   │
│  │  • Syncthing │  │  • Open      │  │  • WOL Relay         │   │
│  │  • Fleet     │  │    WebUI     │  │  • Always On         │   │
│  │    Scripts   │  │  • Docker    │  │                      │   │
│  │  • Node      │  │  • Nginx     │  │                      │   │
│  │    Exporter  │  │  • Funnel    │  │                      │   │
│  │              │  │              │  │                      │   │
│  │              │  │              │  │                      │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  HP Compaq   │  │   Lenovo     │  │   Raspberry Pi 4     │   │
│  │  AMD A10     │  │  Intel Core M│  │  ARM Cortex-A72      │   │
│  │  19GB RAM    │  │  8GB RAM     │  │  4GB RAM             │   │
│  │              │  │              │  │                      │   │
│  │              │  │              │  │  • Live Camera       │   │
│  │  • WAN NAS   │  │              │  │    (Motion)          │   │
│  │  • Samba     │  │  • Sysadmin  │  │  • Motion Alerts     │   │
│  │  • Syncthing │  │    Sandbox   │  │    (Slack)           │   │
│  │  • mergerfs  │  │              │  │  • Auto Storage      │   │
│  └──────────────┘  └──────────────┘  │    Rotation          │   │
│                                      └──────────────────────┘   │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │  Dell 5070   │  │  Dell 7440   │                             │
│  │  i7-9700T    │  │  i5-1345U    │                             │
│  │  32GB RAM    │  │  16GB RAM    │                             │
│  │              │  │              │                             │
│  │  • K8s Worker│  │  • K8s       │                             │
│  │  • Syncthing │  │    Control   │                             │
│  │  • Secondary │  │    Plane     │                             │
│  │    Desktop   │  │  • Grafana   │                             │
│  │  • KVM/QEMU  │  │    Kiosk     │                             │
│  │              │  │    Display   │                             │
│  │              │  │  • Always On │                             │
│  └──────────────┘  └──────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
```

## Fleet Overview

| Machine | OS | CPU | RAM | Storage | Tailscale IP | Role |
|---------|------|-----|-----|---------|-------------|------|
| MacBook Pro M1 | macOS | Apple M1 | 8GB | 512GB SSD | 100.112.165.19 | Daily driver, command center |
| Dell 7050 | Debian 13 | i7-6700 (4c/8t) | 32GB | 465GB HDD | 100.117.229.28 | Docker, Ollama, video hosting |
| Sony VAIO | Debian 13 | Core2 Duo T6600 | 4GB | 128GB SSD | 100.96.120.65 | Monitoring (Grafana/Prometheus), WOL relay |
| HP Compaq | Debian 12 | AMD A10-5800K | 19GB | 256GB SSD + 1TB HDD + 500GB HDD | 100.64.249.4 | K8s worker, WAN NAS, Syncthing |
| Lenovo Yoga 3 Pro | Debian 12 | Intel Core M 5Y70 | 8GB | 238GB SSD | 100.66.222.35 | sysadmin sandbox |
| Raspberry Pi 4 | Debian 13 | ARM Cortex-A72 | 4GB | 32GB SD + 2x USB drives | 100.73.143.19 | Live camera (Motion), motion alerts |
| Dell 5070 | Linux Mint | i7-9700T | 32GB | 1TB NVMe SSD | 100.108.102.105 | K8s worker, secondary desktop, Syncthing, KVM/QEMU host |
| Dell 7440 | Debian 13 | i5-1345U | 16GB | 512GB NVMe | 100.106.110.55 | K8s control plane, Grafana kiosk display, always-on |

## What's Running

### Kubernetes (k3s) — 3-Node Cluster
- **Control plane + worker:** Dell 7440 (always-on, NVMe datastore)
- **Worker nodes:** Dell 5070, Dell 7050
- **Expandable:** HP Compaq and Lenovo join as workers when online
- Flannel runs over `tailscale0` so the cluster spans the mesh VPN
- Automatic pod scheduling and self-healing across nodes
- Cluster install, node join, and workload manifests in [`kubernetes/`](kubernetes/README.md)

### Monitoring Stack (Sony VAIO)
- **Prometheus** scraping Node Exporter and smartctl_exporter from all machines
- **Grafana** dashboards for CPU, RAM, disk, network, SMART health, and CPU temperature
- **Alerting** via Slack webhooks for:
  - CPU temperature above 176°F (80°C)
  - Machine offline
  - Disk health degradation (reallocated sectors)
  - Disk space above 85%
  - RAM usage above 90%
  - Camera storage above 75%

### Grafana Kiosk Display (Dell 7440)
- Dedicated always-on monitoring display running Google Chrome in fullscreen
- Auto-launches on boot via systemd user service targeting GNOME Wayland
- Displays Node Exporter Full dashboard; touchpad usable for navigating between dashboards
- Screen controlled remotely from Mac via `screen-off-7440.sh` and `screen-on-7440.sh`
- Battery charge threshold set to 80% via udev rule to prevent swelling while always docked
- Connected via D-Link D6000 USB-C dock for ethernet and charging

### WAN NAS (HP Compaq)
- Built from scratch on a bare HP Compaq Pro 6305
- WiFi driver (RTL88x2BU) compiled from source with DKMS for auto-rebuild on kernel updates
- Debian 12 installed offline using DVD ISO as local apt repository
- Two drives (1TB HGST + 500GB Seagate) formatted ext4 and merged via **mergerfs**
- **Samba** file sharing with multi-user access
- **Syncthing** Docker container auto-syncing Mac, Dell 5070, and NAS

### Self-Hosted AI (Dell 7050)
- **Ollama** running llama3.2, gemma3:12b, and deepseek-r1:14b models
- **Open WebUI** providing a ChatGPT-like interface accessible on the tailnet
- CPU-only inference on i7-6700

### Video Hosting (Dell 7050)
- **Nginx** Docker container serving a homelab project video
- Publicly accessible via **Tailscale Funnel** with a QR code for sharing

### Live Camera + Motion Alerts (Raspberry Pi 4)
- **Motion** software capturing 640x480 at 15fps from USB webcam
- Live stream accessible on port 8081 via Tailscale
- 60-second MKV clip recording with automated storage rotation
- **Slack webhook alerts** triggered automatically on motion detection
- Custom **systemd timer** checks disk usage every 5 minutes and switches recording to a secondary USB drive at 90% capacity

### Fleet Automation (Mac)
- **update-fleet.sh** — runs apt update/upgrade on all machines
- **reboot-fleet.sh** — reboots selected machines remotely
- **shutdown-fleet.sh** — shuts down the fleet
- **dellHpOff.sh** — targeted shutdown for Dell 7050, HP NAS, and Dell 7440
- **wake-dellHp.sh** — Wake-on-LAN via Sony relay
- **screen-off-7440.sh** — turns off Dell 7440 display remotely via gdbus over SSH
- **screen-on-7440.sh** — turns on Dell 7440 display remotely via gdbus over SSH
- All scripts handle offline machines gracefully

### Wake-on-LAN
- WOL enabled in BIOS and OS (ethtool + systemd service) on Dell 7050 and HP Compaq
- Sony VAIO acts as always-on relay — Mac SSHs into Sony over Tailscale, Sony sends magic packets on the local LAN
- Required disabling Deep Sleep on Dell 7050 BIOS

### File Synchronization
- **Syncthing** syncs school, aws, job, and random folders across Mac ↔ HP NAS ↔ Dell 5070
- HP NAS acts as always-on hub — machines sync when they come online
- Accessible via Samba from any machine on the tailnet

## Related Projects

- [homelab-bootloader](https://github.com/michaelcraw/homelab-bootloader) — 512-byte x86 bootloader written in NASM assembly that displays fleet status on boot, runs in QEMU

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
│   ├── dellHpOff.sh             # Targeted Dell 7050 + HP + Dell 7440 shutdown
│   ├── wake-dellHp.sh           # WOL wake Dell + HP
│   ├── motion-storage-check.sh  # Pi camera storage rotation
│   ├── screen-off-7440.sh       # Turn off Dell 7440 display remotely
│   ├── screen-on-7440.sh        # Turn on Dell 7440 display remotely
│   ├── k8s-install.sh           # Stand up k3s cluster (server + agents)
│   └── k8s-deploy.sh            # Apply homelab manifests to the cluster
├── configs/
│   ├── prometheus/
│   │   └── prometheus.yml       # Prometheus scrape configuration
│   ├── grafana/
│   │   └── alert-queries.md     # Grafana alert queries (Slack webhook)
│   ├── docker/
│   │   ├── dell-7050-docker.md  # Dell 7050 container configs
│   │   └── hp-docker.md         # HP Compaq container configs
│   ├── 7440/
│   │   └── grafana-kiosk.service # Systemd user service for Grafana kiosk
│   ├── samba/                   # Samba share configuration
│   └── syncthing/               # Syncthing configuration
├── kubernetes/
│   ├── README.md                # k3s cluster install + node join
│   └── manifests/               # Applyable workloads (namespace, dashboard)
└── screenshots/                 # Grafana dashboard screenshots
```

## Skills & Technologies

- **Infrastructure:** Kubernetes (k3s), Docker, Tailscale, Nginx, Samba, mergerfs, KVM/QEMU
- **Monitoring:** Prometheus, Grafana, Node Exporter, smartctl_exporter, Slack alerting
- **AI/ML:** Ollama, Open WebUI, LLM inference
- **Security:** SSH key authentication, UFW, WireGuard
- **Automation:** Bash scripting, systemd services, Wake-on-LAN, DKMS
- **Low-level:** x86 assembly (NASM), BIOS interrupts, bootloader development
- **Operating Systems:** Debian 12/13, Linux Mint, macOS
- **Networking:** Layer 2/3, WOL, DNS, SMB, mesh VPN

## Roadmap

- [ ] Extend fleet to AWS (hybrid cloud architecture)
- [ ] Deploy services across on-prem and cloud with Kubernetes federation
- [ ] Deploy Pi-hole for network-wide ad blocking
- [ ] Replace Sony VAIO SSD with Samsung PM851 mSATA

## Author

**Michael Crawford**  
Computer Science, University of Denver  
AWS Certified Cloud Practitioner

[LinkedIn](https://www.linkedin.com/in/michael-crawford-2a17aa1ab) | [GitHub](https://github.com/michaelcraw)
