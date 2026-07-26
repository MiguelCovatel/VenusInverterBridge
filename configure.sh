#!/bin/sh
set -eu

CONF_DIR="/data/conf"
CONF_FILE="$CONF_DIR/venus_inverter_bridge.ini"
SAMPLE_FILE="/data/apps/VenusInverterBridge/config.sample.ini"

mkdir -p "$CONF_DIR"

if [ ! -f "$CONF_FILE" ]; then
  if [ -f "$SAMPLE_FILE" ]; then
    cp -a "$SAMPLE_FILE" "$CONF_FILE"
  else
    cat > "$CONF_FILE" <<'INIEOF'
[Setup]
Name = Venus Inverter Bridge
Serial = 000000
DeviceInstance = 28
DeviceIp = 127.0.0.1
RelayId = 0
DcVoltageFallback = 12.8
InverterEfficiency = 0.90
debug = false
INIEOF
  fi
fi

current_value() {
  key="$1"
  fallback="$2"
  value="$(grep -E "^[[:space:]]*$key[[:space:]]*=" "$CONF_FILE" 2>/dev/null | tail -n 1 | sed 's/^[^=]*=[[:space:]]*//')"
  [ -n "$value" ] && echo "$value" || echo "$fallback"
}

set_value() {
  key="$1"
  value="$2"
  if grep -qE "^[[:space:]]*$key[[:space:]]*=" "$CONF_FILE"; then
    sed -i "s|^[[:space:]]*$key[[:space:]]*=.*|$key = $value|" "$CONF_FILE"
  else
    sed -i "/^\[Setup\]/a $key = $value" "$CONF_FILE"
  fi
}

OLD_NAME="$(current_value Name "Venus Inverter Bridge")"
OLD_SERIAL="$(current_value Serial "000000")"
OLD_INSTANCE="$(current_value DeviceInstance "28")"
OLD_IP="$(current_value DeviceIp "127.0.0.1")"
OLD_RELAY="$(current_value RelayId "0")"
OLD_DC_FALLBACK="$(current_value DcVoltageFallback "12.8")"
OLD_EFFICIENCY="$(current_value InverterEfficiency "0.90")"

printf "Name [%s]: " "$OLD_NAME"
read NAME
printf "Serial [%s]: " "$OLD_SERIAL"
read SERIAL
printf "DeviceInstance [%s]: " "$OLD_INSTANCE"
read DEVICE_INSTANCE
printf "DeviceIp [%s]: " "$OLD_IP"
read DEVICE_IP
printf "RelayId [%s]: " "$OLD_RELAY"
read RELAY_ID
printf "DcVoltageFallback [%s]: " "$OLD_DC_FALLBACK"
read DC_FALLBACK
printf "InverterEfficiency [%s]: " "$OLD_EFFICIENCY"
read EFFICIENCY

[ -n "$NAME" ] || NAME="$OLD_NAME"
[ -n "$SERIAL" ] || SERIAL="$OLD_SERIAL"
[ -n "$DEVICE_INSTANCE" ] || DEVICE_INSTANCE="$OLD_INSTANCE"
[ -n "$DEVICE_IP" ] || DEVICE_IP="$OLD_IP"
[ -n "$RELAY_ID" ] || RELAY_ID="$OLD_RELAY"
[ -n "$DC_FALLBACK" ] || DC_FALLBACK="$OLD_DC_FALLBACK"
[ -n "$EFFICIENCY" ] || EFFICIENCY="$OLD_EFFICIENCY"

set_value Name "$NAME"
set_value Serial "$SERIAL"
set_value DeviceInstance "$DEVICE_INSTANCE"
set_value DeviceIp "$DEVICE_IP"
set_value RelayId "$RELAY_ID"
set_value DcVoltageFallback "$DC_FALLBACK"
set_value InverterEfficiency "$EFFICIENCY"

svc -t /service/VenusInverterBridge 2>/dev/null || true

echo "Updated: $CONF_FILE"
