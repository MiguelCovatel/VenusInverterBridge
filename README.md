# Venus Inverter Bridge

Venus Inverter Bridge exposes a Shelly-compatible power device as a Victron inverter service on Venus OS D-Bus.

It shows AC voltage, AC current, AC power, relay state and estimated DC battery consumption in Venus OS. The ON/OFF control from the Venus OS inverter screen controls the configured Shelly relay.

## Features

- Standalone Venus OS service
- No SetupHelper required
- No GuiMods required
- No GUI1 or GUI2 QML patches
- Works through D-Bus
- Configurable name, serial, device instance, device IP and relay ID
- Reads real battery voltage from Venus OS
- Estimates DC power and current using configurable inverter efficiency
- Intended for Raspberry Pi running Venus OS and Victron GX devices such as Cerbo GX

## Compatible devices

The device must expose a Shelly Gen2, Plus or Pro compatible HTTP RPC API.

The bridge reads:

    http://DEVICE_IP/rpc/Shelly.GetStatus

The bridge controls:

    http://DEVICE_IP/rpc/Switch.Set?id=RELAY_ID&on=true
    http://DEVICE_IP/rpc/Switch.Set?id=RELAY_ID&on=false

The selected relay must provide:

- apower
- voltage
- current
- output

## Shelly setup

Before installing the bridge:

1. Give the Shelly device a fixed IP address.
2. Confirm Venus OS can reach that IP.
3. Test this from Venus OS:

    wget -qO- http://SHELLY_IP/rpc/Shelly.GetStatus

You should see JSON data containing `switch:0`, or the relay number you want to use.

## Install

SSH into Venus OS as root and run:

    cd /tmp
    rm -rf VenusInverterBridge-standalone-installer VenusInverterBridge.tar.gz
    wget -O VenusInverterBridge.tar.gz https://github.com/MiguelCovatel/VenusInverterBridge/archive/refs/heads/standalone-installer.tar.gz
    tar -xzf VenusInverterBridge.tar.gz
    cd VenusInverterBridge-standalone-installer
    sh install.sh
    sh configure.sh

The app is installed in:

    /data/apps/VenusInverterBridge

The config file is:

    /data/conf/venus_inverter_bridge.ini

The service is:

    /service/VenusInverterBridge

## Configuration

Run:

    sh /data/apps/VenusInverterBridge/configure.sh

Or edit:

    /data/conf/venus_inverter_bridge.ini

Example:

    [Setup]
    Name = Inversor Camper
    Serial = 000000
    DeviceInstance = 28
    DeviceIp = 192.168.1.40
    RelayId = 0
    DcVoltageFallback = 12.8
    InverterEfficiency = 0.90
    debug = false

## Configuration options

Name: name shown in Venus OS.

Serial: serial number published on D-Bus.

DeviceInstance: Victron device instance. Default is 28.

DeviceIp: IP address of the Shelly-compatible device.

RelayId: relay number to read and control. Usually 0.

DcVoltageFallback: fallback DC voltage if Venus OS does not provide battery voltage.

InverterEfficiency: inverter efficiency used for DC estimation. Use 0.90 for 90 percent efficiency. Values like 90 are also accepted and treated as 0.90.

debug: set to true for extra logs.

## DC calculation

The Shelly measures the AC side. The bridge estimates the DC side using:

    estimated DC power = AC power / inverter efficiency
    estimated DC current = estimated DC power / battery voltage

Battery voltage is read from Venus OS:

    /Dc/Battery/Voltage

If that value is not available, the bridge uses:

    DcVoltageFallback

Suggested fallback values:

- 12 V system: 12.8
- 24 V system: 25.6
- 48 V system: 51.2

## Restart

After changing config:

    svc -t /service/VenusInverterBridge

## Update

    cd /tmp
    rm -rf VenusInverterBridge-standalone-installer VenusInverterBridge.tar.gz
    wget -O VenusInverterBridge.tar.gz https://github.com/MiguelCovatel/VenusInverterBridge/archive/refs/heads/standalone-installer.tar.gz
    tar -xzf VenusInverterBridge.tar.gz
    cd VenusInverterBridge-standalone-installer
    sh install.sh

Existing config is preserved.

## Uninstall

Remove the service but keep config:

    sh /data/apps/VenusInverterBridge/uninstall.sh

Remove service, app files, config and logs:

    sh /data/apps/VenusInverterBridge/uninstall.sh --purge

## Troubleshooting

Check status:

    svstat /service/VenusInverterBridge

Check logs:

    tail -n 80 /var/log/VenusInverterBridge/current

Check published D-Bus values:

    dbus -y com.victronenergy.inverter.bridge /Dc/0/Voltage GetValue
    dbus -y com.victronenergy.inverter.bridge /Dc/0/Power GetValue
    dbus -y com.victronenergy.inverter.bridge /Ac/Out/L1/P GetValue

## Notes

This project does not install GuiMods and does not patch GUI1 or GUI2. The inverter appears through D-Bus, which is safer across Venus OS versions and GX devices.

Any future visual GUI modification should be packaged separately.

## Disclaimer

This project is community provided and is not an official Victron Energy product.
