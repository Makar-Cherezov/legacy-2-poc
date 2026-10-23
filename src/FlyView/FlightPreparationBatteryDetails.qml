import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls

import "FlightPreparationRules.js" as Rules

/// Per-battery measurements are shown only while telemetry is usable.
ColumnLayout {
    id: root

    property var preparation

    spacing: ScreenTools.defaultFontPixelHeight / 3

    FlightPreparationSection {
        Layout.fillWidth: true
        title: qsTr("Battery details")
        description: qsTr("Check each installed battery. Voltage and temperature limits depend on the battery type.")
    }

    Repeater {
        model: root.preparation.live ? root.preparation.snapshot.batteries : []

        ColumnLayout {
            Layout.fillWidth: true
            property var battery: modelData

            FlightPreparationMetric {
                Layout.fillWidth: true
                label: qsTr("Battery %1 voltage").arg(Rules.inRange(battery.id, 0, 255) ? battery.id : index)
                value: battery.available && Rules.inRange(battery.voltage, 0, 1000)
                       ? qsTr("%1 V").arg(battery.voltage.toFixed(2)) : qsTr("Unavailable")
            }

            FlightPreparationMetric {
                Layout.fillWidth: true
                label: qsTr("Temperature")
                value: battery.available && Rules.inRange(battery.temperature, -100, 200)
                       ? qsTr("%1 °C").arg(battery.temperature.toFixed(1)) : qsTr("Unavailable")
            }
        }
    }

    QGCLabel {
        Layout.fillWidth: true
        visible: !root.preparation.live || root.preparation.snapshot.batteries.length === 0
        text: qsTr("Waiting for live battery measurements.")
        wrapMode: Text.WordWrap
    }
}
