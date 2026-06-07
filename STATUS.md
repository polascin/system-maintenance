# Final status report
Date: 2026-06-07

## Repository
- Remote: https://github.com/polascin/system-maintenance
- Default branch: master
- Head commit (local): f432bb3

## Installed components
Tracked in this repository and installed on the system:
- Maintenance script: `/usr/local/sbin/weekly-maintenance.sh`
- systemd service: `/etc/systemd/system/weekly-maintenance.service`
- systemd timer: `/etc/systemd/system/weekly-maintenance.timer`
- Logrotate: `/etc/logrotate.d/weekly-maintenance`
- Log file: `/var/log/weekly-maintenance.log`

## Schedule
- Timer unit: `weekly-maintenance.timer`
- Enabled: yes
- Active: yes (waiting)
- Next trigger: Sun 2026-06-14 03:35:57 CEST

## Last maintenance run
- systemd result: success
- ExecMainStatus: 0
- Note: firmware update checks (`fwupdmgr`) are configured to soft-fail (logged as WARN and ignored).

## System health
- Failed systemd units: none

## Relevant service status
- smbd: active
- nmbd: active
- ssh: inactive

## Operational procedures
For installation, manual runs, logs, log rotation, and schedule customisation, see `README.md`.
