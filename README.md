# Venus Inverter Bridge

Venus Inverter Bridge exposes a Shelly-compatible power device as a Victron inverter service on Venus OS D-Bus.

It shows voltage, current, power and relay state in Venus OS. The ON/OFF control from the inverter screen controls the configured Shelly relay.

## Features

- Standalone Venus OS service
- No SetupHelper required
- No GuiMods required
- No GUI1 or GUI2 QML patches
- Works through D-Bus
- Configurable name, serial, device instance, device IP and relay ID
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

## Install

SSH into Venus OS as root and run:

    cd /tmp
    rm -rf VenusInverterBridge-main VenusInverterBridge.tar.gz
    wget -O VenusInverterBridge.tar.gz https://github.com/MiguelCovatel/VenusInverterBridge/archive/refs/heads/main.tar.gz
    tar -xzf VenusInverterBridge.tar.gz
    cd VenusInverterBridge-main
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
    debug = false

Restart after changing config:

    svc -t /service/VenusInverterBridge

## Update

    cd /tmp
    rm -rf VenusInverterBridge-main VenusInverterBridge.tar.gz
    wget -O VenusInverterBridge.tar.gz https://github.com/MiguelCovatel/VenusInverterBridge/archive/refs/heads/main.tar.gz
    tar -xzf VenusInverterBridge.tar.gz
    cd VenusInverterBridge-main
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

Test the Shelly-compatible device from Venus OS:

    wget -qO- http://DEVICE_IP/rpc/Shelly.GetStatus

## Notes

This project does not install GuiMods and does not patch GUI1 or GUI2. The inverter appears through D-Bus, which is safer across Venus OS versions and GX devices.

Any future visual GUI modification should be packaged separately.

## Disclaimer

This project is community provided and is not an official Victron Energy product.
