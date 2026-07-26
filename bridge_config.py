import configparser
import os
import shutil


class BridgeConfig:
    def __init__(self):
        self.config = configparser.ConfigParser()
        self.app_dir = os.path.dirname(os.path.realpath(__file__))
        self.config_file = "/data/conf/venus_inverter_bridge.ini"

        os.makedirs(os.path.dirname(self.config_file), exist_ok=True)

        if not os.path.exists(self.config_file):
            sample_config_file = os.path.join(self.app_dir, "config.sample.ini")
            shutil.copy(sample_config_file, self.config_file)

        self.config.read(self.config_file)

    def get_product_name(self):
        return self.config.get("Setup", "Name", fallback="Venus Inverter Bridge")

    def get_serial(self):
        return self.config.get("Setup", "Serial", fallback="000000")

    def get_device_instance(self):
        return self.config.getint("Setup", "DeviceInstance", fallback=28)

    def get_device_ip(self):
        return self.config.get("Setup", "DeviceIp", fallback="127.0.0.1")

    def get_relay_id(self):
        return self.config.getint("Setup", "RelayId", fallback=0)

    def get_debug(self):
        return self.config.getboolean("Setup", "debug", fallback=False)

    def write_to_config(self, value, section, key):
        if not self.config.has_section(section):
            self.config.add_section(section)

        self.config[section][key] = str(value)

        with open(self.config_file, "w") as configfile:
            self.config.write(configfile)

    @staticmethod
    def get_version():
        version_file = os.path.join(os.path.dirname(os.path.realpath(__file__)), "version")
        with open(version_file, "r") as file:
            return file.read().strip()
