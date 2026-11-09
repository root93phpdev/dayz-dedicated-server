# DayZ Dedicated Server Troubleshooting Guide

This document provides practical diagnostic procedures for common DayZ Dedicated Server issues on Ubuntu Linux.

The examples use the project environment:

- Linux user: `dayz`
- Server directory: `/home/dayz/server-test`
- SteamCMD: `/home/dayz/steamcmd/steamcmd.sh`
- systemd service: `dayz.service`
- Profiles directory: `/home/dayz/server-test/profiles`

Adapt paths and service names if your installation differs.

## 1. Server does not start

### Check systemd status

```bash
sudo systemctl status dayz.service --no-pager -l
```

Look for:
- `Active: failed` — the service failed to start.
- `code=exited` — the server process exited.
- `Permission denied` — check file and directory permissions.
- `No such file or directory` — check executable and configuration paths.

### Inspect recent service logs

```bash
sudo journalctl -u dayz.service -n 100 --no-pager
```

Follow logs in real time:

```bash
sudo journalctl -u dayz.service -f
```

### Check the server executable

```bash
ls -lh /home/dayz/server-test/DayZServer
file /home/dayz/server-test/DayZServer
```

Verify that the executable exists and has execute permissions.

### Check the service configuration

```bash
sudo systemctl cat dayz.service
```

Verify:
- `User` and `Group` are set to `dayz`.
- `WorkingDirectory` points to the server directory.
- `ExecStart` references the correct executable.
- The configuration file exists in the working directory.

After changing the service file:

```bash
sudo systemctl daemon-reload
sudo systemctl restart dayz.service
```

## 2. Permission problems

The DayZ server should run as its dedicated Linux user rather than root.

Check ownership:

```bash
stat -c '%U:%G %a %n' /home/dayz/server-test
stat -c '%U:%G %a %n' /home/dayz/steamcmd
```

Check the server executable:

```bash
stat -c '%U:%G %a %n' /home/dayz/server-test/DayZServer
```

Expected project ownership:

```text
dayz:dayz
```

Check whether the server user can access the installation:

```bash
sudo -u dayz test -x /home/dayz/server-test/DayZServer \
    && echo "Executable is accessible" \
    || echo "Executable is not accessible"
```

Do not solve permission problems by recursively assigning unrestricted permissions. Identify the affected file or directory and correct its ownership or permissions specifically.

## 3. SteamCMD problems

### Check SteamCMD installation

```bash
ls -lh /home/dayz/steamcmd/steamcmd.sh
```

Run SteamCMD as the dedicated user:

```bash
sudo -u dayz /home/dayz/steamcmd/steamcmd.sh +quit
```

### Update the Dedicated Server

Stop the service first:

```bash
sudo systemctl stop dayz.service
```

Run the update:

```bash
sudo -u dayz /home/dayz/steamcmd/steamcmd.sh \
    +force_install_dir /home/dayz/server-test \
    +login YOUR_STEAM_USERNAME \
    +app_update 223350 validate \
    +quit
```

Start the service:

```bash
sudo systemctl start dayz.service
```

SteamCMD may require interactive password and Steam Guard verification.

Never store Steam passwords, Steam Guard codes, or authentication files in the Git repository.

### Verify the installed server files

```bash
ls -lh /home/dayz/server-test/DayZServer
```

If the executable is missing, inspect the SteamCMD output and verify the installation directory and account access.

## 4. Workshop mods are missing or not loading

### Check downloaded Workshop content

```bash
ls -lah /home/dayz/server-test/steamapps/workshop/content/221100/
```

The Workshop content directory uses the DayZ Workshop application ID `221100`.

### Check symbolic links

```bash
ls -lah /home/dayz/server-test/ | grep -E '1559212036|1564026768|DayZ-Expansion|DabsFramework'
```

Inspect a specific link:

```bash
readlink -f /home/dayz/server-test/@DayZ-Expansion-Core
```

The resolved path should point to the corresponding Workshop content directory.

Check for broken symbolic links:

```bash
find -L /home/dayz/server-test -maxdepth 1 -type l -print
```

If a link is broken, verify that the corresponding Workshop directory exists before recreating it.

### Check the mod startup parameter

Inspect the service:

```bash
sudo systemctl cat dayz.service
```

Verify that the `-mod` parameter contains the intended mod directory names and load order.

The project uses:

```text
1559212036
@DabsFramework
@DayZ-Expansion-Core
@DayZ-Expansion-AI
1564026768
```

The actual startup parameter must match the names of the directories or symbolic links in the server root.

## 5. Mod signature key problems

DayZ uses `.bikey` files to validate mod signatures.

List the server keys:

```bash
ls -lah /home/dayz/server-test/keys/
```

Find keys in Workshop content:

```bash
find /home/dayz/server-test/steamapps/workshop/content/221100 \
    -type f -iname "*.bikey"
```

Compare files to identify identical keys:

```bash
sha256sum /home/dayz/server-test/keys/*.bikey
```

If a mod reports a signature verification problem:

1. Identify which mod reports the error.
2. Locate its `.bikey` file in the Workshop directory.
3. Verify that the required key is present in the server `keys` directory.
4. Avoid unnecessary duplicate keys.
5. Restart the server and inspect the logs again.

Do not disable signature verification as a general workaround.

## 6. Configuration problems

### Verify the configuration file

```bash
ls -lh /home/dayz/server-test/serverDZ.cfg
```

Inspect the mission template:

```bash
grep -n -A 8 'class Missions' \
    /home/dayz/server-test/serverDZ.cfg
```

The project uses the Livonia mission template:

```cpp
template = "dayzOffline.enoch";
```

A missing or incorrect mission template can prevent the expected map from loading.

### Check startup parameters

The project service uses:

```text
-config=serverDZ.cfg
-port=2302
-profiles=profiles
-dologs
-adminlog
-netlog
-freezecheck
```

Verify that the configuration file and profiles directory match the actual installation.

Do not publish real server passwords or other sensitive configuration values.

## 7. Server process and network diagnostics

### Check the service process

```bash
pgrep -a -f DayZServer
```

Check listening ports:

```bash
sudo ss -tulpn
```

The project deployment was observed listening on:

| Port | Protocol |
|---|---|
| 2302 | UDP |
| 2304 | UDP |
| 27016 | UDP |

If a port is not listening, first verify that the server process is running and inspect its logs. Do not assume that a missing port alone identifies the cause.

## 8. DayZ logs and profiles

The project uses:

```text
/home/dayz/server-test/profiles/
```

Find recent log files:

```bash
sudo find /home/dayz/server-test/profiles \
    -type f \
    \( -iname "*.RPT" -o -iname "script_*.log" -o -iname "error_*.log" \) \
    -printf '%TY-%Tm-%Td %TH:%TM %p\n' \
    | sort -r \
    | head -30
```

Inspect recent errors:

```bash
sudo find /home/dayz/server-test/profiles \
    -type f \
    \( -iname "error_*.log" -o -iname "script_*.log" \) \
    -printf '%T@ %p\n' \
    | sort -nr \
    | head -10
```

Follow the systemd journal:

```bash
sudo journalctl -u dayz.service -f
```

When investigating a problem, compare the timestamp in the DayZ log with the systemd journal to identify events around the same time.

## 9. Restart and recovery procedure

When the server becomes unresponsive or a configuration change requires a restart:

```bash
sudo systemctl restart dayz.service
```

Check the result:

```bash
sudo systemctl status dayz.service --no-pager
```

Inspect recent logs:

```bash
sudo journalctl -u dayz.service -n 100 --no-pager
```

If the service fails again, collect the journal output and the latest DayZ `.RPT` or error log before attempting further changes.

## 10. Useful diagnostic command reference

| Purpose | Command |
|---|---|
| Service status | `sudo systemctl status dayz` |
| Recent service logs | `sudo journalctl -u dayz -n 100` |
| Live service logs | `sudo journalctl -u dayz -f` |
| Server process | `pgrep -a -f DayZServer` |
| Listening ports | `sudo ss -tulpn` |
| Server file permissions | `stat -c '%U:%G %a %n' /home/dayz/server-test` |
| Check mod links | `ls -lah /home/dayz/server-test/` |
| Resolve a mod link | `readlink -f /home/dayz/server-test/@DayZ-Expansion-Core` |
| Find mod keys | `find /home/dayz/server-test/steamapps/workshop/content/221100 -type f -iname "*.bikey"` |
| Find recent RPT logs | `find /home/dayz/server-test/profiles -type f -iname "*.RPT"` |

## 11. Reporting an issue

When documenting a new problem, include:

- A short description of the symptom.
- The command used to reproduce or diagnose it.
- Relevant systemd journal output.
- The latest relevant DayZ log excerpt.
- The cause, if confirmed.
- The resolution, if tested.

Remove passwords, authentication tokens, private IP addresses if necessary, and other sensitive information before sharing diagnostic output publicly.

---

For installation and initial configuration, see the [DayZ Dedicated Server Installation Guide](../installation/dayz-server-installation.md).

For monitoring architecture, metrics, dashboards, and centralized logging, see the [main project README](../../README.md).