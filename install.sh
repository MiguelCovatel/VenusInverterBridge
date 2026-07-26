#!/bin/sh
set -eu

APP_NAME="VenusInverterBridge"
SRC_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
APP_DIR="/data/apps/$APP_NAME"
CONF_DIR="/data/conf"
CONF_FILE="$CONF_DIR/venus_inverter_bridge.ini"
SERVICE_SRC="$APP_DIR/service"
SERVICE_LINK="/service/$APP_NAME"
LOG_DIR="/var/log/$APP_NAME"
RC_LOCAL="/data/rc.local"
BACKUP_DIR="/data/backups/${APP_NAME}-install-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"
mkdir -p "$APP_DIR"
mkdir -p "$CONF_DIR"
mkdir -p "$LOG_DIR"

if [ -e "$SERVICE_LINK" ]; then
  svc -d "$SERVICE_LINK" 2>/dev/null || true
  rm -f "$SERVICE_LINK" 2>/dev/null || true
fi

cp -a "$SRC_DIR/VenusInverterBridge.py" "$APP_DIR/"
cp -a "$SRC_DIR/bridge_config.py" "$APP_DIR/"
cp -a "$SRC_DIR/bridge_broker.py" "$APP_DIR/" 2>/dev/null || true
cp -a "$SRC_DIR/vreg_link_item.py" "$APP_DIR/"
cp -a "$SRC_DIR/utils.py" "$APP_DIR/"
cp -a "$SRC_DIR/config.sample.ini" "$APP_DIR/"
cp -a "$SRC_DIR/configure.sh" "$APP_DIR/"
cp -a "$SRC_DIR/uninstall.sh" "$APP_DIR/"
cp -a "$SRC_DIR/restart.sh" "$APP_DIR/"
cp -a "$SRC_DIR/version" "$APP_DIR/" 2>/dev/null || echo "0.1.0" > "$APP_DIR/version"

if [ ! -f "$CONF_FILE" ]; then
  cp -a "$SRC_DIR/config.sample.ini" "$CONF_FILE"
fi

mkdir -p "$SERVICE_SRC/log"

cat > "$SERVICE_SRC/run" <<'RUNEOF'
#!/bin/sh
exec 2>&1
exec /data/apps/VenusInverterBridge/VenusInverterBridge.py
RUNEOF

cat > "$SERVICE_SRC/log/run" <<'LOGEOF'
#!/bin/sh
exec 2>&1
exec multilog t s25000 n4 /var/log/VenusInverterBridge
LOGEOF

chmod +x "$APP_DIR/VenusInverterBridge.py"
chmod +x "$APP_DIR/configure.sh" "$APP_DIR/uninstall.sh" "$APP_DIR/restart.sh"
chmod +x "$SERVICE_SRC/run" "$SERVICE_SRC/log/run"

ln -s "$SERVICE_SRC" "$SERVICE_LINK"

if [ ! -f "$RC_LOCAL" ]; then
  printf '%s\n' '#!/bin/sh' > "$RC_LOCAL"
fi

cp -a "$RC_LOCAL" "$BACKUP_DIR/rc.local.bak" 2>/dev/null || true

sed -i '/VenusInverterBridge standalone autostart/,/VenusInverterBridge standalone autostart end/d' "$RC_LOCAL"

cat >> "$RC_LOCAL" <<'RCEOF'

# VenusInverterBridge standalone autostart
if [ -d /data/apps/VenusInverterBridge/service ]; then
  chmod +x /data/apps/VenusInverterBridge/VenusInverterBridge.py
  chmod +x /data/apps/VenusInverterBridge/service/run
  chmod +x /data/apps/VenusInverterBridge/service/log/run
  mkdir -p /var/log/VenusInverterBridge
  [ -e /service/VenusInverterBridge ] || ln -s /data/apps/VenusInverterBridge/service /service/VenusInverterBridge
fi
# VenusInverterBridge standalone autostart end
RCEOF

chmod +x "$RC_LOCAL"

sleep 2
svc -u "$SERVICE_LINK" 2>/dev/null || true
sleep 2

echo "Installed: $APP_DIR"
echo "Config: $CONF_FILE"
echo "Service: $SERVICE_LINK"
echo "Log: $LOG_DIR/current"
