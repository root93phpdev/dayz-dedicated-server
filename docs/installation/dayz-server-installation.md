# DayZ Dedicated Server Installation Guide

This guide describes how to install and configure a DayZ Dedicated Server on Ubuntu Linux using SteamCMD, Steam Workshop mods, and systemd.

The configuration is based on a working DayZ server deployment used in this project.

## 1. Environment

| Component | Value |
|---|---|
| Operating system | Ubuntu Server 26.04 LTS |
| Server user | `dayz` |
| Server directory | `/home/dayz/server-test` |
| SteamCMD directory | `/home/dayz/steamcmd` |
| SteamCMD executable | `/home/dayz/steamcmd/steamcmd.sh` |
| DayZ Server app ID | `223350` |
| Steam Workshop app ID | `221100` |
| Game port | UDP 2302 |
| Additional detected ports | UDP 2304, UDP 27016 |
| Map | Livonia (`dayzOffline.enoch`) |

## 2. Create a dedicated Linux user

Run the following commands with an administrative account:

```bash
sudo adduser --disabled-password --gecos "" dayz

sudo mkdir -p /home/dayz/steamcmd
sudo mkdir -p /home/dayz/server-test

sudo chown -R dayz:dayz /home/dayz
```

A dedicated Linux user is recommended to run the game server without root privileges.

If the `dayz` user already exists, skip the `adduser` command.

## 3. Install SteamCMD prerequisites

Enable 32-bit package architecture and install the required libraries:

```bash
sudo dpkg --add-architecture i386
sudo apt update

sudo apt install -y \
    wget \
    tar \
    lib32gcc-s1 \
    lib32stdc++6
```

SteamCMD for Linux uses 32-bit components, so the required compatibility libraries must be available.

## 4. Install SteamCMD

Download and extract SteamCMD:

```bash
sudo -u dayz bash -c '
cd /home/dayz/steamcmd
wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzf steamcmd_linux.tar.gz
'
```

Set ownership:

```bash
sudo chown -R dayz:dayz /home/dayz/steamcmd
```

Check the installation:

```bash
sudo -u dayz /home/dayz/steamcmd/steamcmd.sh +quit
```

SteamCMD should start and update itself if necessary.

## 5. Download DayZ Dedicated Server

The DayZ Dedicated Server Steam application ID is `223350`.

Run SteamCMD:

```bash
sudo -u dayz /home/dayz/steamcmd/steamcmd.sh \
    +force_install_dir /home/dayz/server-test \
    +login YOUR_STEAM_USERNAME \
    +app_update 223350 validate \
    +quit
```

Replace `YOUR_STEAM_USERNAME` with your Steam account name.

SteamCMD may request your password and Steam Guard verification code interactively. Never publish credentials, authentication files, or verification codes.

After installation, verify the server executable:

```bash
ls -lh /home/dayz/server-test/DayZServer
```

## 6. Download Steam Workshop mods

The Steam Workshop application ID for DayZ is `221100`.

The following mods are used in this project:

| Workshop ID | Mod |
|---|---|
| `1559212036` | CF |
| `1564026768` | Community-Online-Tools |
| `2291785308` | DayZ Expansion Core |
| `2545327648` | Dabs Framework |
| `2792982069` | DayZ Expansion AI |

Download the mods using SteamCMD:

```bash
sudo -u dayz /home/dayz/steamcmd/steamcmd.sh \
    +force_install_dir /home/dayz/server-test \
    +login YOUR_STEAM_USERNAME \
    +workshop_download_item 221100 1559212036 \
    +workshop_download_item 221100 1564026768 \
    +workshop_download_item 221100 2291785308 \
    +workshop_download_item 221100 2545327648 \
    +workshop_download_item 221100 2792982069 \
    +quit
```

Workshop content is stored under:

```text
/home/dayz/server-test/steamapps/workshop/content/221100/
```

## 7. Create symbolic links for mods

The server uses symbolic links in its root directory to reference Workshop content.

Run the following commands:

```bash
cd /home/dayz/server-test

sudo -u dayz ln -s \
    /home/dayz/server-test/steamapps/workshop/content/221100/1559212036 \
    1559212036

sudo -u dayz ln -s \
    /home/dayz/server-test/steamapps/workshop/content/221100/1564026768 \
    1564026768

sudo -u dayz ln -s \
    /home/dayz/server-test/steamapps/workshop/content/221100/2291785308 \
    @DayZ-Expansion-Core

sudo -u dayz ln -s \
    /home/dayz/server-test/steamapps/workshop/content/221100/2545327648 \
    @DabsFramework

sudo -u dayz ln -s \
    /home/dayz/server-test/steamapps/workshop/content/221100/2792982069 \
    @DayZ-Expansion-AI
```

These commands assume the destination links do not already exist.

Verify the links:

```bash
ls -lah /home/dayz/server-test/
```

## 8. Install mod signature keys

DayZ uses `.bikey` files to verify mod signatures.

The server's key directory is:

```text
/home/dayz/server-test/keys/
```

Inspect the Workshop directories for mod keys:

```bash
find /home/dayz/server-test/steamapps/workshop/content/221100 \
    -type f -iname "*.bikey"
```

Copy the required keys from the installed mods into the server's `keys` directory. Avoid unnecessary duplicate keys.

The working configuration in this project contains:

```text
keys/
├── Expansion.bikey
├── Jacob_Mango_V3.bikey
├── dab.bikey
└── dayz.bikey
```

Check the directory:

```bash
ls -lah /home/dayz/server-test/keys/
```

## 9. Configure serverDZ.cfg

The main server configuration file is:

```text
/home/dayz/server-test/serverDZ.cfg
```

Example configuration based on this project:

```cpp
hostname = "DayDZ DevOps Project";

password = "";
passwordAdmin = "";

description = "DayZ Dedicated Server";
enableWhitelist = 0;

maxPlayers = 60;

verifySignatures = 2;
forceSameBuild = 1;

disableVoN = 0;
vonCodecQuality = 20;

shardId = "YOUR_SHARD_ID";

thirdPersonView = 1;
disableCrosshair = 0;
disablePersonalLight = 1;

lightingConfig = 0;

serverTime = "SystemTime";
serverTimeAcceleration = 12;
serverNightTimeAcceleration = 1;
serverTimePersistent = 0;

guaranteedUpdates = 1;

loginQueueConcurrentPlayers = 5;
loginQueueMaxPlayers = 500;

instanceId = 1;
storageAutoFix = 1;

class Missions
{
    class DayZ
    {
        template = "dayzOffline.enoch";
    };
};
```

Important settings:

- `hostname` — server name.
- `password` — optional player password.
- `passwordAdmin` — administrator password.
- `maxPlayers` — maximum player count.
- `verifySignatures` — mod signature verification.
- `serverTime` — server time source.
- `serverTimeAcceleration` — time acceleration.
- `template` — mission template. `dayzOffline.enoch` selects Livonia.

Use your own unique shard identifier and secure passwords where required. Do not commit real credentials to GitHub.

## 10. Create a systemd service

Create the service file:

```bash
sudo nano /etc/systemd/system/dayz.service
```

Example service configuration:

```ini
[Unit]
Description=DayZ Dedicated Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=dayz
Group=dayz
WorkingDirectory=/home/dayz/server-test

ExecStart=-/home/dayz/server-test/DayZServer -config=serverDZ.cfg -port=2302 -profiles=profiles -dologs -adminlog -netlog -freezecheck "-mod=1559212036;@DabsFramework;@DayZ-Expansion-Core;@DayZ-Expansion-AI;1564026768;"

Restart=on-failure
RestartSec=10
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
```

The `-mod` parameter must reference the actual mod directory names and preserve the intended load order.

If you use a different installation directory, update `WorkingDirectory` and `ExecStart` accordingly.

## 11. Enable and start the server

Reload systemd:

```bash
sudo systemctl daemon-reload
```

Enable automatic startup:

```bash
sudo systemctl enable dayz.service
```

Start the server:

```bash
sudo systemctl start dayz.service
```

Check its status:

```bash
sudo systemctl status dayz.service
```

Follow the service logs:

```bash
sudo journalctl -u dayz.service -f
```

## 12. Verify listening ports

Check the ports opened by the running DayZ process:

```bash
sudo ss -tulpn
```

The working deployment in this project was observed listening on:

| Port | Protocol |
|---|---|
| 2302 | UDP |
| 2304 | UDP |
| 27016 | UDP |

Port requirements may vary depending on server configuration and installed mods.

## 13. Useful administration commands

| Task | Command |
|---|---|
| Start server | `sudo systemctl start dayz` |
| Stop server | `sudo systemctl stop dayz` |
| Restart server | `sudo systemctl restart dayz` |
| Check status | `sudo systemctl status dayz` |
| Follow logs | `sudo journalctl -u dayz -f` |
| View recent logs | `sudo journalctl -u dayz -n 100` |
| Enable autostart | `sudo systemctl enable dayz` |
| Disable autostart | `sudo systemctl disable dayz` |

## 14. Update the server

To update the DayZ Dedicated Server:

```bash
sudo systemctl stop dayz

sudo -u dayz /home/dayz/steamcmd/steamcmd.sh \
    +force_install_dir /home/dayz/server-test \
    +login YOUR_STEAM_USERNAME \
    +app_update 223350 validate \
    +quit

sudo systemctl start dayz
```

For Workshop mods, repeat the corresponding `workshop_download_item` commands.

Before updating, consider backing up the server configuration, profiles, and persistent storage.

## 15. Project-specific notes

This installation is part of a DevOps learning and monitoring project.

The server runs as a dedicated Linux user and is managed by systemd. Its metrics and logs are collected by a separate monitoring stack using Prometheus, Grafana, Loki, and Grafana Alloy.

See the main [README](../../README.md) for the monitoring architecture, dashboards, metrics, and centralized logging configuration.