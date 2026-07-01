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

## Compatible devices

This integration currently works with devices that expose a Shelly Gen2/Plus/Pro compatible HTTP RPC API.

The bridge reads data from:

```text
http://DEVICE_IP/rpc/Shelly.GetStatus

## Compatible devices

This integration currently works with devices that expose a Shelly Gen2/Plus/Pro compatible HTTP RPC API.

The bridge reads data from:

```text
http://DEVICE_IP/rpc/Shelly.GetStatus
```

And controls the relay using:

```text
http://DEVICE_IP/rpc/Switch.Set?id=0&on=true
http://DEVICE_IP/rpc/Switch.Set?id=0&on=false
```

The device must provide these values under switch:0: apower, voltage, current and output.

## Shelly setup

Before installing the bridge, make sure your Shelly device is already working on the same network as the Venus OS device.

Recommended steps:

1. Give the Shelly a fixed IP address from your router.
2. Open the Shelly web interface from a browser.
3. Confirm this URL works:

```text
http://SHELLY_IP/rpc/Shelly.GetStatus
```

Example:

```text
http://192.168.1.40/rpc/Shelly.GetStatus
```

You should see a JSON response with switch:0, voltage, current, power and output state.

## ON/OFF control

The ON/OFF button in the Venus OS inverter screen controls relay switch:0 on the configured device.

When the inverter is switched ON, the bridge sends /rpc/Switch.Set?id=0&on=true.
When the inverter is switched OFF, it sends /rpc/Switch.Set?id=0&on=false.

## Bridge configuration

After installation, edit:

```text
/data/conf/venus_inverter_bridge.ini
```

Main options:

```ini
[Setup]
Name = Inversor Camper
Serial = 000000
DeviceIp = 192.168.1.40
debug = false
```

Option meaning:

- Name: name shown in the Venus OS UI.
- Serial: serial shown on D-Bus.
- DeviceIp: IP address of the Shelly-compatible device.
- debug: enables extra logging when set to true.

After changing the configuration, restart the service:

```sh
svc -t /service/VenusInverterBridge
```

## Troubleshooting

Check the service status:

```sh
svstat /service/VenusInverterBridge
```

Check logs:

```sh
tail -n 80 /var/log/VenusInverterBridge/current
```

If the bridge cannot read the device, check:

- the DeviceIp value;
- that Venus OS can reach the device IP;
- that http://DEVICE_IP/rpc/Shelly.GetStatus works;
- that the device has a switch:0 relay.
