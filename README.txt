Weekly system maintenance (Mint/Ubuntu/Debian)

Files tracked in this repository:
- usr/local/sbin/weekly-maintenance.sh
- etc/systemd/system/weekly-maintenance.service
- etc/systemd/system/weekly-maintenance.timer
- etc/logrotate.d/weekly-maintenance

Install (as root):
  sudo install -m 0755 usr/local/sbin/weekly-maintenance.sh /usr/local/sbin/weekly-maintenance.sh
  sudo install -m 0644 etc/systemd/system/weekly-maintenance.service /etc/systemd/system/weekly-maintenance.service
  sudo install -m 0644 etc/systemd/system/weekly-maintenance.timer /etc/systemd/system/weekly-maintenance.timer
  sudo install -m 0644 etc/logrotate.d/weekly-maintenance /etc/logrotate.d/weekly-maintenance
  sudo systemctl daemon-reload
  sudo systemctl enable --now weekly-maintenance.timer

Manual run:
  sudo systemctl start weekly-maintenance.service

Logs:
  sudo tail -n 200 /var/log/weekly-maintenance.log
