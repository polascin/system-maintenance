# system-maintenance
Weekly deep maintenance for Linux Mint / Ubuntu / Debian.
This repository tracks:
- a maintenance script (APT repair + full upgrade + clean-up)
- a systemd service + timer (weekly schedule)
- logrotate configuration for the maintenance log

## What it does
The maintenance job runs the following (where available) and logs everything:
- Package health/repair:
  - `dpkg --configure -a`
  - `apt-get check`
  - `apt-get -f install`
- Updates/upgrades:
  - `apt-get update`
  - `apt-get full-upgrade` (non-interactive; keeps existing config files)
- Clean-up:
  - `apt-get autoremove --purge`
  - `apt-get autoclean` / `apt-get clean`
- Optional updates:
  - Flatpak updates (if `flatpak` is installed)
  - Snap refresh (if `snap` is installed)
  - Firmware updates via `fwupdmgr` (if installed). Any `fwupdmgr` errors are logged as `WARN(...)` and ignored.
- Storage/log maintenance:
  - SSD trim (`fstrim -av`) if available
  - journal vacuum (`journalctl --vacuum-time=14d`)
  - tmpfiles clean (`systemd-tmpfiles --clean`)
  - locate database update (`updatedb`) if available

## Files in this repo
- Script: `usr/local/sbin/weekly-maintenance.sh`
- systemd service: `etc/systemd/system/weekly-maintenance.service`
- systemd timer: `etc/systemd/system/weekly-maintenance.timer`
- logrotate config: `etc/logrotate.d/weekly-maintenance`

## Install / upgrade
All installation steps must be run as root.
From the repository root:
- Install files:
  - `sudo install -m 0755 usr/local/sbin/weekly-maintenance.sh /usr/local/sbin/weekly-maintenance.sh`
  - `sudo install -m 0644 etc/systemd/system/weekly-maintenance.service /etc/systemd/system/weekly-maintenance.service`
  - `sudo install -m 0644 etc/systemd/system/weekly-maintenance.timer /etc/systemd/system/weekly-maintenance.timer`
  - `sudo install -m 0644 etc/logrotate.d/weekly-maintenance /etc/logrotate.d/weekly-maintenance`
- Reload systemd and enable the timer:
  - `sudo systemctl daemon-reload`
  - `sudo systemctl enable --now weekly-maintenance.timer`

To upgrade later, pull the repo and re-run the same install commands.

## Verify schedule
- Check timer is enabled + active:
  - `systemctl is-enabled weekly-maintenance.timer`
  - `systemctl is-active weekly-maintenance.timer`
- See next run time:
  - `systemctl list-timers --no-pager | grep weekly-maintenance`

## Run manually
- Run once:
  - `sudo systemctl start weekly-maintenance.service`
- Follow service logs:
  - `sudo journalctl -u weekly-maintenance.service -f`

## Logs
- Main log file: `/var/log/weekly-maintenance.log`
- File permissions are set for safe reading:
  - owned by `root:adm` when the `adm` group exists
  - mode `0640`

View the log:
- `sudo tail -n 200 /var/log/weekly-maintenance.log`

## Log rotation
The log rotates weekly and keeps 12 compressed rotations.
Configuration: `etc/logrotate.d/weekly-maintenance`

Dry-run logrotate:
- `sudo logrotate -d /etc/logrotate.d/weekly-maintenance`

## Customise the schedule
Edit the timer unit:
- `sudo systemctl edit --full weekly-maintenance.timer`
Then:
- `sudo systemctl daemon-reload`
- `sudo systemctl restart weekly-maintenance.timer`

By default the timer uses:
- `OnCalendar=Sun *-*-* 03:30:00`
- `RandomizedDelaySec=1h` (avoids predictable spikes)
- `Persistent=true` (runs after boot if a run was missed while powered off)

## Uninstall
- `sudo systemctl disable --now weekly-maintenance.timer`
- `sudo rm -f /etc/systemd/system/weekly-maintenance.timer /etc/systemd/system/weekly-maintenance.service`
- `sudo systemctl daemon-reload`
- Optional:
  - `sudo rm -f /usr/local/sbin/weekly-maintenance.sh`
  - `sudo rm -f /etc/logrotate.d/weekly-maintenance`
  - `sudo rm -f /var/log/weekly-maintenance.log`

## Notes
- If `/var/run/reboot-required` exists after a run, a reboot is recommended.
- If you use full disk encryption, read any `fwupdmgr` warnings carefully before applying firmware updates.