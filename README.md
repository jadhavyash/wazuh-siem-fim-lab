# 🛡️ Wazuh Home Lab — SIEM & File Integrity Monitoring

> A free, open-source home lab deploying **Wazuh** as a full SIEM platform. A Windows host machine runs the Wazuh Agent, forwarding security events and file integrity alerts in real time to a Wazuh Manager hosted on an Ubuntu Server VM (VirtualBox). The setup demonstrates log analysis, real-time file change detection, intrusion detection, and a live security dashboard.

---

## 📐 Architecture Overview

\`\`\`
┌─────────────────────────────────────────────────┐
│              VirtualBox (Host Machine)           │
│                                                  │
│   ┌──────────────────────┐                       │
│   │  Ubuntu Server 22.04 │  ◄── Bridged Adapter  │
│   │  IP: 192.168.1.100   │                       │
│   │                      │                       │
│   │  ● Wazuh Manager     │                       │
│   │  ● Wazuh Indexer     │                       │
│   │  ● Wazuh Dashboard   │                       │
│   └──────────┬───────────┘                       │
│              │ TCP 1514                           │
│   ┌──────────▼───────────┐                       │
│   │  Windows Host        │                       │
│   │  IP: 192.168.1.105   │                       │
│   │                      │                       │
│   │  ● Wazuh Agent       │                       │
│   │  ● FIM: C:\Users\    │                       │
│   │        abc\Test      │                       │
│   └──────────────────────┘                       │
└─────────────────────────────────────────────────┘
\`\`\`

| Component | Host | Role |
|---|---|---|
| Wazuh Manager | Ubuntu 22.04 (VirtualBox) | Collects, analyses, and stores data from agents. Hosts web dashboard. |
| Wazuh Agent | Windows (host machine) | Sends logs and system events to the Wazuh manager in real time. |
| VirtualBox Network | Bridged Adapter | Places the Ubuntu VM on the same LAN as the Windows host. |

---

## ✨ Features Demonstrated

- **Log Analysis** — Windows Security Event logs collected and indexed from the agent
- **File Integrity Monitoring (FIM)** — Real-time detection of file creation, modification, and deletion via Syscheck
- **Intrusion Detection** — Rules-based alerting on suspicious behaviour patterns
- **Vulnerability Detection** — CVE scanning on the monitored endpoint
- **Live Security Dashboard** — Web UI showing alerts, agent status, FIM events, and severity distribution

---

## 🔧 Prerequisites

- VirtualBox installed on the Windows host
- Ubuntu Server 22.04+ ISO installed in VirtualBox with **Bridged Adapter** networking
- Internet access on the Ubuntu VM
- Administrator access on the Windows host
- Minimum **4 GB RAM** assigned to the Ubuntu VM (Wazuh Indexer is resource-intensive)

---

## 🚀 Setup Guide

### Step 1 — Install Wazuh Manager on Ubuntu VM

**Add the Wazuh GPG Key:**
\`\`\`bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --dearmor -o \
  /usr/share/keyrings/wazuh-archive-keyring.gpg
\`\`\`

**Download and run the all-in-one installation script:**
\`\`\`bash
curl -sO https://packages.wazuh.com/4.12/wazuh-install.sh && \
  sudo bash ./wazuh-install.sh -a -i
\`\`\`

| Flag | Meaning |
|---|---|
| `-a` | Installs all components — Manager, Indexer, and Dashboard |
| `-i` | Runs in interactive mode |

> ⚠️ **Save the credentials** printed at the end of the install script — these are your dashboard login details.

---

### Step 2 — Access the Wazuh Dashboard

\`\`\`bash
# Get your Ubuntu VM's IP address
ifconfig | grep inet
\`\`\`

Open a browser and navigate to:
\`\`\`
https://<ubuntu-vm-ip>
\`\`\`
Accept the browser security warning (self-signed certificate) and log in with the credentials from Step 1.

---

### Step 3 — Install the Wazuh Agent on Windows

Download the latest MSI installer from the official Wazuh docs:
[Wazuh Agent for Windows](https://documentation.wazuh.com/current/installation-guide/wazuh-agent/wazuh-agent-package-windows.html)

Run the MSI with default settings. The `WazuhSvc` Windows service will be installed automatically.

---

### Step 4 — Register the Agent with the Manager

**On the Ubuntu Manager**, generate an agent key:
\`\`\`bash
sudo /var/ossec/bin/manage_agents
\`\`\`

Follow the prompts:
1. Press `A` → add agent → name it `WindowsHost` → leave IP blank → confirm with `y`
2. Press `E` → enter ID `001` → **copy the full key string**

**On Windows**, apply the key:
1. Open **Wazuh Agent Manager** from the Start Menu
2. Set **Manager IP** to your Ubuntu VM's IP (e.g., `192.168.1.100`)
3. Click **Import Key** → paste the key → click **Save** → **Restart**

Verify the agent connected:
\`\`\`bash
sudo /var/ossec/bin/agent_control -l
# Output: ID: 001, Name: WindowsHost, IP: 192.168.1.105, Active
\`\`\`

---

### Step 5 — Configure File Integrity Monitoring (FIM)

Open the agent config file on Windows (as Administrator):
\`\`\`
C:\Program Files (x86)\ossec-agent\ossec.conf
\`\`\`

Inside the `<syscheck>` block, add:
\`\`\`xml
<directories realtime="yes">C:\Users\abc\Test</directories>
\`\`\`

> 💡 Replace the path with any folder you want to monitor. Multiple `<directories>` lines are supported.

**Restart the agent to apply changes:**
\`\`\`powershell
# PowerShell (Administrator)
Restart-Service -Name WazuhSvc

# OR Command Prompt (Administrator)
net stop WazuhSvc && net start WazuhSvc
\`\`\`

---

### Step 6 — Verify the Setup

1. Open the Wazuh Dashboard → **Endpoint Security → Agents** → confirm `WindowsHost` shows **Active**
2. Click the agent → go to **File Integrity Monitoring**
3. On Windows, create / modify / delete files inside `C:\Users\abc\Test`
4. FIM alerts appear in the dashboard **within seconds**

---

## 📊 FIM Rule IDs Reference

| Rule ID | Event | Level |
|---|---|---|
| `550` | File content modified (checksum changed) | 7 — Medium |
| `553` | File deleted from monitored directory | 7 — Medium |
| `554` | File added to monitored directory | 9 — High |
| `555` | File ownership or permissions changed | 7 — Medium |
| `556` | Monitored directory path not found | 4 — Low |

---

## ⚡ Quick Command Reference

| Task | Command |
|---|---|
| Install Wazuh (Ubuntu) | `sudo bash ./wazuh-install.sh -a -i` |
| Get Ubuntu VM IP | `ifconfig \| grep inet` |
| Register agent | `sudo /var/ossec/bin/manage_agents` |
| List agents + status | `sudo /var/ossec/bin/agent_control -l` |
| Restart Wazuh Manager | `sudo systemctl restart wazuh-manager` |
| Stop all Wazuh services | `sudo systemctl stop wazuh-manager wazuh-indexer wazuh-dashboard` |
| Restart Windows agent | `net stop WazuhSvc && net start WazuhSvc` |
| FIM config file path | `C:\Program Files (x86)\ossec-agent\ossec.conf` |

---

## 🧹 Cleanup

Stop all services when the lab is not in use:
\`\`\`bash
sudo systemctl stop wazuh-manager wazuh-indexer wazuh-dashboard
\`\`\`

Restart when needed:
\`\`\`bash
sudo systemctl start wazuh-manager wazuh-indexer wazuh-dashboard
\`\`\`

> ⚠️ Wazuh Indexer (OpenSearch) uses significant memory. Assign at least **4 GB RAM** to the Ubuntu VM in VirtualBox → VM Settings → System → Base Memory.

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| Wazuh v4.12 | SIEM, FIM, IDS, vulnerability scanning |
| Ubuntu Server 22.04 | Wazuh Manager host (VirtualBox VM) |
| Windows 10 | Wazuh Agent endpoint |
| VirtualBox | Virtualisation (Bridged Adapter networking) |
| OpenSearch (Indexer) | Log storage and search backend |
| Wazuh Dashboard | Web-based security UI |

---

## 📚 References

- [Wazuh Official Documentation](https://documentation.wazuh.com)
- [Wazuh Installation Guide](https://documentation.wazuh.com/current/installation-guide/index.html)
- [Wazuh File Integrity Monitoring Docs](https://documentation.wazuh.com/current/user-manual/capabilities/file-integrity/index.html)
- Original lab guide by **Royden Rebello (The Social Dork)** — [YouTube Video](https://youtu.be/QT81wcuoRFY)

---

## ⚠️ Disclaimer

This project is for **educational and home lab purposes only**. Do not expose Wazuh ports to the public internet without proper authentication, TLS certificates, and firewall rules. Always follow official Wazuh documentation for production deployments.

---

## 📄 License

MIT License — free to fork, adapt, and build on.
