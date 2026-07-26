#!/bin/sh
set -eu

APP_NAME="VenusInverterBridge"
APP_DIR="/data/apps/$APP_NAME"
SERVICE_LINK="/service/$APP_NAME"
RC_LOCAL="/data/rc.local"
LOG_DIR="/var/log/$APP_NAME"
CONF_FILE="/data/conf/venus_inverter_bridge.ini"
BACKUP_DIR="/data/backups/${APP_NAME}-uninstall-$(date +%Y%m%d-%H%M%S)"

PURGE="false"
[ "${1:-}" = "--purge" ] && PURGE="true"

mkdir -p "$BACKUP_DIR"

svc -d "$SERVICE_LINK" 2>/dev/null || true
rm -f "$SERVICE_LINK" 2>/dev/null || true

if [ -f "$RC_LOCAL" ]; then
  cp -a "$RC_LOCAL" "$BACKUP_DIR/rc.local.bak" 2>/dev/null || true
  sed -i '/VenusInverterBridge standalone autostart/,/VenusInverterBridge standalone autostart end/d' "$RC_LOCAL"
fi

if [ "$PURGE" = "true" ]; then
  cp -a "$APP_DIR" "$BACKUP_DIR/app" 2>/dev/null || true
  cp -a "$CONF_FILE" "$BACKUP_DIR/venus_inverter_bridge.ini" 2>/dev/null || true
  rm -rf "$APP_DIR" 2>/dev/null || true
  rm -f "$CONF_FILE" 2>/dev/null || true
  rm -rf "$LOG_DIR" 2>/dev/null || true
fi

echo "Removed service: $SERVICE_LINK"
echo "Backup: $BACKUP_DIR"
