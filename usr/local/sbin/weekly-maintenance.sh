#!/usr/bin/env bash
# Weekly deep maintenance for Debian/Ubuntu/Mint systems.
# Logs to: /var/log/weekly-maintenance.log

set -u

LOG_FILE="/var/log/weekly-maintenance.log"

log() {
  local msg="$1"
  local ts
  ts="$(date -Is)"
  printf '%s %s\n' "$ts" "$msg" | tee -a "$LOG_FILE" | logger -t weekly-maintenance || true
}

run_step() {
  local name="$1"; shift
  log "==> START: $name"
  # shellcheck disable=SC2068
  "$@" >>"$LOG_FILE" 2>&1
  local rc=$?
  if [ $rc -eq 0 ]; then
    log "<== OK: $name"
  else
    log "<== FAIL($rc): $name"
  fi
  return $rc
}

# Like run_step, but never fails the overall run. Useful for optional components
# (e.g. firmware updates) where failures are acceptable.
run_step_softfail() {
  local name="$1"; shift
  log "==> START: $name"
  # shellcheck disable=SC2068
  "$@" >>"$LOG_FILE" 2>&1
  local rc=$?
  if [ $rc -eq 0 ]; then
    log "<== OK: $name"
  else
    log "<== WARN($rc): $name (ignored)"
  fi
  return 0
}

require_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "This script must run as root." >&2
    exit 1
  fi
}

main() {
  require_root

  umask 027
  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE"
  if getent group adm >/dev/null 2>&1; then
    chown root:adm "$LOG_FILE" || true
  fi
  chmod 0640 "$LOG_FILE" || true

  log "Weekly maintenance started"
  log "Host: $(hostname -f 2>/dev/null || hostname)"

  export DEBIAN_FRONTEND=noninteractive

  run_step "Disk usage (before)" df -h || true

  # Repairs first
  run_step "dpkg --configure -a" dpkg --configure -a || true
  run_step "apt-get update" apt-get update
  run_step "apt-get check" apt-get check || true
  run_step "apt-get -f install" apt-get -y -f install || true

  # Full upgrade
  run_step "apt-get full-upgrade" apt-get -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    full-upgrade

  # Clean-up
  run_step "apt-get autoremove --purge" apt-get -y autoremove --purge || true
  run_step "apt-get autoclean" apt-get -y autoclean || true
  run_step "apt-get clean" apt-get -y clean || true

  # Flatpak updates (if installed)
  if command -v flatpak >/dev/null 2>&1; then
    run_step "flatpak update" flatpak update -y || true
    run_step "flatpak uninstall --unused" flatpak uninstall --unused -y || true
  fi

  # Snap updates (if installed)
  if command -v snap >/dev/null 2>&1; then
    run_step "snap refresh" snap refresh || true
  fi

  # Firmware updates (if supported)
  if command -v fwupdmgr >/dev/null 2>&1; then
    run_step_softfail "fwupdmgr refresh" fwupdmgr refresh --force
    run_step_softfail "fwupdmgr get-updates" fwupdmgr get-updates
    run_step_softfail "fwupdmgr update" fwupdmgr update -y
  fi

  # Trim SSDs
  if command -v fstrim >/dev/null 2>&1; then
    run_step "fstrim -av" fstrim -av || true
  fi

  # Clean systemd journal and tmp files
  if command -v journalctl >/dev/null 2>&1; then
    run_step "journalctl --vacuum-time=14d" journalctl --vacuum-time=14d || true
  fi
  if command -v systemd-tmpfiles >/dev/null 2>&1; then
    run_step "systemd-tmpfiles --clean" systemd-tmpfiles --clean || true
  fi

  # Update locate database
  if command -v updatedb >/dev/null 2>&1; then
    run_step "updatedb" updatedb || true
  fi

  run_step "Disk usage (after)" df -h || true

  if [ -f /var/run/reboot-required ]; then
    log "NOTE: reboot is required (/var/run/reboot-required exists)"
  fi

  log "Weekly maintenance finished"
}

main "$@"
