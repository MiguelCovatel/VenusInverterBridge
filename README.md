# Venus Inverter Bridge

Venus Inverter Bridge is a Venus OS / Victron GX integration that exposes a compatible network power device as a Victron inverter service over D-Bus.

It allows the device to appear in the Venus OS UI as an inverter, showing AC voltage, current, power and relay state.

## Status

Early public release. Tested on Venus OS v3.63 on Raspberry Pi.

## Features

- Publishes an inverter service to Venus OS D-Bus
- Shows the device as an inverter in the Venus OS UI
- Reads AC voltage, current, power and relay state
- Allows ON/OFF control from the inverter screen
- Configurable visible name, serial number and device IP
- SetupHelper / PackageManager compatible

## Configuration

After installation, edit:

```text
/data/conf/venus_inverter_bridge.ini
```

Example:

```ini
[Setup]
Name = Inversor Camper
Serial = 000000
DeviceIp = 192.168.1.40
debug = false
```

## Install

Install using SetupHelper PackageManager on Venus OS.

Package values:

```text
GitHub user: YOUR_GITHUB_USER
Repository: VenusInverterBridge
Branch: main
Package name: VenusInverterBridge
```

## Service

Service: /service/VenusInverterBridge
Logs: /var/log/VenusInverterBridge/current

## Disclaimer

This project is community provided and is not an official Victron Energy product.
