/////// new menu for system shutdown

import QtQuick 1.1
import "utils.js" as Utils
import com.victron.velib 1.0

MbPage
{
	id: root
	title: qsTr("Venus Inverter")
    VBusItem { id: deviceItem; bind: Utils.path("com.victronenergy.inverter.device", "/Connected") }

    VBusItem { id: deviceItemIp; bind: Utils.path("com.victronenergy.inverter.device/Settings/Venus/Setup/VenusIp") }
    VBusItem { id: brokerItemIp; bind: Utils.path("com.victronenergy.inverter.device/Settings/Venus/MQTTBroker/Address") }

    model: VisibleItemModel
    {
        // Setup
        MbItemText
        {
            text: qsTr("Venus Inverter not running")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignLeft
            show: !deviceItem.valid
        }

        MbEditBox {
            description: "Inverter Name"
            maximumLength: 30
            item.bind: "com.victronenergy.inverter.device/Settings/Venus/Setup/Name"
            writeAccessLevel: User.AccessUser
            show: deviceItem.valid
        }

        MbEditBox {
            description: "Serial"
            maximumLength: 30
            item.bind: "com.victronenergy.inverter.device/Settings/Venus/Setup/Serial"
            writeAccessLevel: User.AccessUser
            show: deviceItem.valid
        }

        MbEditBoxIp {
            description: "Venus IP"
            item.value: deviceItemIp.value
            show: deviceItem.valid
        }

        // Broker

        MbEditBox {
            description: "MQTT Broker Name"
            maximumLength: 30
            item.bind: "com.victronenergy.inverter.device/Settings/Venus/MQTTBroker/Name"
            writeAccessLevel: User.AccessUser
            show: deviceItem.valid
        }

        MbEditBoxIp {
            description: "MQTT Broker Address"
            item.value: brokerItemIp.value
            show: deviceItem.valid
        }

        MbEditBox {
            description: "MQTT Broker Port"
            maximumLength: 6
            numericOnlyLayout: true
            item.bind: "com.victronenergy.inverter.device/Settings/Venus/MQTTBroker/Port"
            writeAccessLevel: User.AccessUser
            show: deviceItem.valid
        }

        MbEditBox {
            description: "Topic L1"
            maximumLength: 50
            item.bind: "com.victronenergy.inverter.device/Settings/Venus/Topics/L1"
            writeAccessLevel: User.AccessUser
            show: deviceItem.valid
        }

        MbEditBox {
            description: "Topic CONFIG"
            maximumLength: 50
            item.bind: "com.victronenergy.inverter.device/Settings/Venus/Topics/CONFIG"
            writeAccessLevel: User.AccessUser
            show: deviceItem.valid
        }

        MbEditBox {
            description: "Topic LWT"
            maximumLength: 50
            item.bind: "com.victronenergy.inverter.device/Settings/Venus/Topics/LWT"
            writeAccessLevel: User.AccessUser
            show: deviceItem.valid
        }

        // Options

        MbEditBox {
            description: "High Temp Warning"
            maximumLength: 3
            numericOnlyLayout: true
            item.bind: "com.victronenergy.inverter.device/Settings/Venus/Warnings/HighTemperature"
            writeAccessLevel: User.AccessUser
            show: deviceItem.valid
        }

        MbEditBox {
            description: "Overload Warning"
            maximumLength: 5
            numericOnlyLayout: true
            item.bind: "com.victronenergy.inverter.device/Settings/Venus/Warnings/Overload"
            writeAccessLevel: User.AccessUser
            show: deviceItem.valid
        }

        MbEditBox {
            description: "Low Voltage Warning"
            maximumLength: 5
            matchString: "0123456789."
            item.bind: "com.victronenergy.inverter.device/Settings/Venus/Warnings/LowVoltage"
            writeAccessLevel: User.AccessUser
            show: deviceItem.valid
        }

        MbEditBox {
            description: "Low Battery Shutdown"
            maximumLength: 5
            matchString: "0123456789."
            item.bind: "com.victronenergy.inverter.device/Settings/Venus/Options/LowBatteryShutdown"
            writeAccessLevel: User.AccessUser
            show: deviceItem.valid
        }

        MbEditBox {
            description: "Charge Detected"
            maximumLength: 5
            matchString: "0123456789."
            item.bind: "com.victronenergy.inverter.device/Settings/Venus/Options/ChargeDetected"
            writeAccessLevel: User.AccessUser
            show: deviceItem.valid
        }


    }
}