#!/usr/bin/env python3
import logging
import requests
import sys
from functools import partial
sys.path.insert(0, '/opt/victronenergy/dbus-systemcalc-py/ext/velib_python')
import dbus
from vedbus import VeDbusService
from gi.repository import GLib
from vreg_link_item import GenericReg, InverterReg, VregLinkItem
from bridge_config import BridgeConfig

DEFAULT_DEVICE_IP = "127.0.0.1"
DC_VOLTAGE_FALLBACK = 12.8

class BridgeInverter:
    def __init__(self, device_ip=DEFAULT_DEVICE_IP, relay_id=0):
        self.status = "OFF"
        self.relay_id = int(relay_id)
        self.voltage = 0.0
        self.current = 0.0
        self.power = 0.0
        self.relay = False
        self.frequency = 50
        self.battery_voltage = DC_VOLTAGE_FALLBACK
        self.eco_mode = False  # eco mode flag
        self.device_ip = device_ip

    def get_mode_and_state(self):
        # Mode: 2 = Inverter on, 5 = Eco, 4 = Off
        # State: 9 = Inverting, 1 = Low power (eco), 0 = Off
        if not self.relay:
            return 4, 0  # Off
        elif self.eco_mode:
            return 5, 1  # Eco mode / low power
        else:
            return 2, 9  # On / Inverting

    def update_from_device(self):
        try:
            url = f"http://{self.device_ip}/rpc/Shelly.GetStatus"
            resp = requests.get(url, timeout=5)
            data = resp.json()

            self.power = data[f"switch:{self.relay_id}"]["apower"]
            self.voltage = data[f"switch:{self.relay_id}"]["voltage"]
            self.current = data[f"switch:{self.relay_id}"]["current"]
            self.relay = data[f"switch:{self.relay_id}"]["output"]
            self.status = "ON" if self.relay else "OFF"

            logging.info(f"Read from device: Power={self.power}, Voltage={self.voltage}, Current={self.current}, Relay={self.relay}")
        except Exception as e:
            logging.warning("Failed to fetch data from device: %s", e)
            self.power = 0.0
            self.voltage = 0.0
            self.current = 0.0
            self.relay = False
            self.status = "OFF"

class BridgeInverterService:
    def __init__(self, device_ip=DEFAULT_DEVICE_IP):
        self.config = BridgeConfig()
        logging.basicConfig(level=logging.DEBUG if self.config.get_debug() else logging.INFO)
        self.inverter = BridgeInverter(self.config.get_device_ip(), self.config.get_relay_id())
        self._dbusservice = VeDbusService("com.victronenergy.inverter.bridge")
        self._setup_paths()
        GLib.timeout_add(5000, self._update)

    def _setup_paths(self):
        self._dbusservice.add_path('/DeviceInstance', self.config.get_device_instance())
        self._dbusservice.add_path('/ProductId', 0xA291)
        self._dbusservice.add_path('/ProductName', self.config.get_product_name())
        self._dbusservice.add_path('/FirmwareVersion', 1)
        self._dbusservice.add_path('/Connected', 1)
        self._dbusservice.add_path('/Serial', self.config.get_serial())

        # AC Output
        self._dbusservice.add_path('/Ac/Out/L1/V', 0.0)
        self._dbusservice.add_path('/Ac/Out/L1/I', 0.0)
        self._dbusservice.add_path('/Ac/Out/L1/P', 0.0)
        self._dbusservice.add_path('/Ac/Out/L1/F', 50.0)

        # DC input (battery)
        self._dbusservice.add_path('/Dc/0/Voltage', 0.0)
        self._dbusservice.add_path('/Dc/0/Current', 0.0)
        self._dbusservice.add_path('/Dc/0/Power', 0.0)

        # Control modes: Off(4), On(2), Eco(5)
        self._dbusservice.add_path('/Mode', 4, writeable=True, onchangecallback=self._handle_mode_change)
        self._dbusservice.add_path(
            '/VregLink',
            0,
            itemtype=partial(
                VregLinkItem,
                getvreg=self._getvreg,
                setvreg=self._setvreg,
            ),
        )

        self._dbusservice.add_path('/State', 0)  # actual state

        # Relay state exposed and writable
        self._dbusservice.add_path('/Relay/0/State', 0, writeable=True, onchangecallback=self._handle_relay_change)

        self._dbusservice.add_path('/UpdateIndex', 0)

    def _handle_mode_change(self, path, value):
        logging.info(f"Mode change requested: {value}")
        return self._apply_mode(value)

    def _apply_mode(self, value):
        try:
            value = int(value)
        except (TypeError, ValueError):
            logging.warning(f"Unsupported mode value: {value}")
            return False

        if value == 2:
            self.inverter.eco_mode = False
            self._set_relay(True)
        elif value == 5:
            self.inverter.eco_mode = True
            self._set_relay(True)
        elif value == 4:
            self.inverter.eco_mode = False
            self._set_relay(False)
        else:
            logging.warning(f"Unsupported mode value: {value}")
            return False
        return True

    def _getvreg(self, regid):
        if regid == InverterReg.VE_REG_DEVICE_MODE.value:
            mode, _ = self.inverter.get_mode_and_state()
            return GenericReg.OK.value, bytes([mode])

        logging.debug(f"Unsupported Vreg read: {regid:#x}")
        return GenericReg.OK.value, bytes()

    def _setvreg(self, regid, data):
        if regid == InverterReg.VE_REG_DEVICE_MODE.value:
            mode = self._decode_vreg_mode(data)
            logging.info(f"Vreg mode change requested: {mode}")
            if self._apply_mode(mode):
                current_mode, _ = self.inverter.get_mode_and_state()
                return GenericReg.OK.value, bytes([current_mode])

        logging.warning(f"Unsupported Vreg write: reg={regid:#x}, data={list(data)}")
        current_mode, _ = self.inverter.get_mode_and_state()
        return GenericReg.OK.value, bytes([current_mode])

    @staticmethod
    def _decode_vreg_mode(data):
        raw = bytes(data)
        if not raw:
            return 4
        if len(raw) >= 4:
            return int.from_bytes(raw[:4], 'little')
        if len(raw) >= 2:
            return int.from_bytes(raw[:2], 'little')
        return raw[0]

    def _handle_relay_change(self, path, value):
        state = bool(value)
        logging.info(f"Relay change requested: {state}")
        self.inverter.eco_mode = False  # manual relay change disables eco
        self._set_relay(state)
        return True

    def _set_relay(self, state: bool):
        try:
            url = f"http://{self.inverter.device_ip}/rpc/Switch.Set?id={self.inverter.relay_id}&on={str(state).lower()}"
            resp = requests.get(url, timeout=5)
            resp.raise_for_status()
            self.inverter.relay = state
            logging.info(f"Relay set to: {state}")
        except Exception as e:
            logging.warning(f"Failed to control device relay: {e}")

    def _read_battery_voltage(self):
        try:
            value = dbus.SystemBus().get_object(
                "com.victronenergy.system",
                "/Dc/Battery/Voltage",
            ).GetValue(dbus_interface="com.victronenergy.BusItem")

            if value is not None and value != [] and value != "":
                voltage = float(value)
                if voltage > 0:
                    self.inverter.battery_voltage = voltage
                    return voltage
        except Exception as e:
            logging.debug("Could not read system battery voltage: %s", e)

        fallback = self.config.get_dc_voltage_fallback()
        self.inverter.battery_voltage = fallback
        return fallback

    def _update(self):
        self.inverter.update_from_device()

        # If eco mode enabled, simulate low power (e.g. 10W)
        power = 10.0 if self.inverter.eco_mode else self.inverter.power

        # AC side
        self._dbusservice['/Ac/Out/L1/V'] = self.inverter.voltage
        self._dbusservice['/Ac/Out/L1/I'] = self.inverter.current
        self._dbusservice['/Ac/Out/L1/P'] = power
        self._dbusservice['/Ac/Out/L1/F'] = self.inverter.frequency

        # DC side
        dc_voltage = self._read_battery_voltage()
        inverter_efficiency = self.config.get_inverter_efficiency()
        dc_power = round(power / inverter_efficiency, 2) if inverter_efficiency > 0 else power
        dc_current = round(dc_power / dc_voltage, 2) if dc_voltage > 0 else 0.0
        self._dbusservice['/Dc/0/Voltage'] = dc_voltage
        self._dbusservice['/Dc/0/Current'] = -dc_current
        self._dbusservice['/Dc/0/Power'] = -dc_power

        # Mode & State
        mode, state = self.inverter.get_mode_and_state()
        self._dbusservice['/Mode'] = mode
        self._dbusservice['/State'] = state
        self._dbusservice['/Relay/0/State'] = int(self.inverter.relay)

        # Update index
        index = self._dbusservice['/UpdateIndex'] + 1
        self._dbusservice['/UpdateIndex'] = 0 if index > 255 else index

        return True  # keep running

def main():
    from dbus.mainloop.glib import DBusGMainLoop
    DBusGMainLoop(set_as_default=True)
    BridgeInverterService()
    GLib.MainLoop().run()

if __name__ == "__main__":
    main()
