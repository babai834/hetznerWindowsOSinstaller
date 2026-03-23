# Windows Server 2025 - Hetzner Automated Installer

Fully automated Windows Server 2025 deployment for Hetzner dedicated servers. **No SCP or file uploads needed** — users only need PuTTY SSH and a single command.

---

## One-Liner Install (PuTTY Users)

SSH into your Hetzner rescue system and run **one command**:

```bash
wget -qO- https://raw.githubusercontent.com/babai834/hetznerWindowsOSinstaller/main/install.sh | bash
```

That's it. Everything is downloaded and executed automatically.

### With Custom Password

```bash
wget -qO- https://raw.githubusercontent.com/babai834/hetznerWindowsOSinstaller/main/install.sh | bash -s -- --password "YourPass123!"
```

### Interactive Wizard (Recommended for First-Time Users)

```bash
wget -qO- https://raw.githubusercontent.com/babai834/hetznerWindowsOSinstaller/main/install.sh | bash -s -- --interactive
```

This walks you through IP, gateway, disk selection, and password step by step.

---

## How It Works (User Perspective)

```
1. Go to Hetzner Robot → Activate Rescue Mode → Reboot
2. Open PuTTY → Connect to your server IP with rescue credentials
3. Paste the one-liner command above
4. Wait 15-30 minutes
5. Connect via RDP to your server IP on port 3389
```

No files to download to your PC. No SCP. No uploads. Just one SSH command.

---

## Features

- **Zero-Upload Workflow** — Everything downloads directly on the server, no SCP needed
- **Interactive Wizard** — Step-by-step guided setup via `--interactive` flag
- **Fully Automated** — ISO download, partitioning, image extraction, boot setup
- **Hetzner Network Ready** — Auto-configures /32 point-to-point routing, static IP, Hetzner DNS
- **UEFI + Legacy BIOS** — Auto-detects boot mode and configures accordingly
- **Two-Disk Workflow** — Uses one disk for Windows and one disk for workspace/downloads
- **RDP Pre-configured** — Remote Desktop enabled and firewall rules applied on first boot
- **Built-in Network Repair** — `C:\fix-network.cmd` auto-placed on Windows drive for KVM use
- **Unattended Install** — Full OOBE bypass, auto-login for setup, and post-install hardening

## File Structure

| File | Where | Purpose |
|---|---|---|
| `install.sh` | Cloud (GitHub/your hosting) | Bootstrap one-liner — downloads & launches installer |
| `install-windows.sh` | Cloud (GitHub/your hosting) | Main installer — fully self-contained, does everything |
| `fix-network.cmd` | Auto-generated on `C:\` | Network repair tool — run from KVM if RDP fails |
| `README.md` | Cloud (GitHub/your hosting) | This documentation |
| `details.txt` | Local only | Your server connection details (not uploaded) |
| `quick-start.sh` | Optional/local | Pre-configured launcher for a specific server |

## Prerequisites

1. **Hetzner dedicated server** in rescue mode (Linux 64-bit)
2. **PuTTY or any SSH client** (just SSH — no SCP, no file transfers)
3. **2 physical drives** — 1 for Windows, 1 for temp workspace/downloads
4. **Minimum 4GB RAM**

---

## Hosting Setup (For Maintainers)

### Option 1: GitHub (Recommended)

1. Create a GitHub repo (for example, `hetznerWindowsOSinstaller`)
2. Upload `install.sh` and `install-windows.sh`
3. Update the `INSTALLER_URL` in `install.sh`:
   ```
   https://raw.githubusercontent.com/babai834/hetznerWindowsOSinstaller/main/install-windows.sh
   ```
4. Users run: `wget -qO- https://raw.githubusercontent.com/babai834/hetznerWindowsOSinstaller/main/install.sh | bash`

### Option 2: Any Web Server

Upload both files to any HTTPS server and update the URL in `install.sh`.

### Option 3: Cloudflare Workers / R2

Great for fast global delivery. Upload files and use the worker URL.

---

## Advanced Usage

```bash
# Download and run directly (no bootstrap)
wget -O /root/install-windows.sh https://raw.githubusercontent.com/babai834/hetznerWindowsOSinstaller/main/install-windows.sh
bash /root/install-windows.sh

# Full manual control
bash install-windows.sh \
  --ip 37.27.49.125 \
  --gateway <auto-detected> \
  --password "YourSecurePass123!" \
  --target-disk /dev/sda \
  --work-disk /dev/sdb \
  --uefi \
  --skip-confirm

# Custom ISO
bash install-windows.sh --iso-url "https://example.com/your-windows.iso"

# Interactive wizard
bash install-windows.sh --interactive

# Safe validation only (no disk changes)
bash install-windows.sh --dry-run
```

### Command-Line Options

| Option | Description | Default |
|---|---|---|
| `--ip <IP>` | Server IPv4 address | Auto-detected from rescue env |
| `--gateway <GW>` | Gateway address | Auto-detected |
| `--password <PASS>` | Administrator password | Auto-generated (16 char) |
| `--iso-url <URL>` | Windows ISO download URL | Built-in URL |
| `--target-disk <DEV>` | Disk for Windows install | First detected disk |
| `--work-disk <DEV>` | Disk for temp workspace | Second detected disk |
| `--skip-confirm` | Skip all confirmation prompts | Off |
| `--uefi` | Force UEFI boot mode | Auto-detect |
| `--bios` | Force Legacy BIOS boot mode | Auto-detect |
| `--interactive`, `-i` | Interactive wizard | Off |
| `--dry-run` | Validate detection and config only | Off |

---

## What Happens Under the Hood

1. **Bootstrap** (`install.sh`) downloads the main installer to `/root/` and launches it
2. **Detection** — Identifies disks, boot mode (UEFI/BIOS), network config, and gateway
3. **Workspace** — Formats the secondary disk as temp workspace for ISO download
4. **Download** — Downloads Windows Server 2025 ISO and (optionally) VirtIO drivers
5. **Partitioning** — Creates proper partition layout on the target disk:
   - UEFI: EFI (512MB) + MSR (16MB) + Windows (rest)
   - BIOS: System Reserved (500MB) + Windows (rest)
6. **Extraction** — Applies the Windows WIM image using wimlib
7. **Configuration** — Injects:
   - `unattend.xml` — Fully unattended Windows setup
   - `setup-network.cmd` — Hetzner /32 network config (runs on first boot)
   - `post-install.cmd` — RDP, firewall, power plan, optimization
   - `fix-network.cmd` — Network repair tool (for KVM console use)
8. **Boot Setup** — Configures bootloader (UEFI boot entry or MBR boot code)
9. **Reboot** — Server boots into Windows Setup, runs fully unattended

## Hetzner Network Configuration

Hetzner uses a unique /32 point-to-point routing setup:

- **Subnet mask**: 255.255.255.255 (/32)
- **Gateway**: Requires a host route before default route works
- **DNS**: 185.12.64.1, 185.12.64.2
- **Routing**: `route add <gateway>/32` then `route add 0.0.0.0/0 via <gateway>`

All handled automatically. If network fails post-install, open KVM console and run `C:\fix-network.cmd`.

---

## Troubleshooting

### Can't connect via RDP after install
- Wait 10-15 minutes for Windows Setup to complete
- Use KVM console to check progress
- Run `C:\fix-network.cmd` from KVM console if network is misconfigured

### Windows stuck at "Getting ready"
- Normal for first boot — can take 10-15 minutes

### Boot failure (0xc000000f) after install
This means the BCD boot configuration has stale device references. Fix via KVM:
1. Mount the Windows Server ISO in Hetzner KVM virtual media
2. Boot from the ISO → **Repair your computer** → **Command Prompt**
3. Run:
   ```bat
   diskpart
   list vol
   ```
4. Identify the EFI partition (small FAT32) and the Windows partition (large NTFS)
5. Assign drive letters and rebuild:
   ```bat
   select volume <EFI_VOL>
   assign letter=S
   select volume <WIN_VOL>
   assign letter=C
   exit
   bcdboot C:\Windows /s S: /f UEFI
   ```
6. Detach the ISO and reboot

### Only one disk available
- This version does not support single-disk installs safely
- Add a second disk before running the installer

---

## Security Notes

- Admin password stored in `/root/windows-credentials.txt` (chmod 600) in rescue system
- Change the password after first login
- Consider hardening RDP (change port, enable NLA)
- 180-day evaluation period starts from first boot

## License

Custom deployment tool. Windows Server is used under Microsoft's evaluation terms (180-day trial). A license key is required for production use.
