import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls
import QGroundControl.FactControls

/// Persistent local review policy, separate from autopilot configuration.
ColumnLayout {
    id: root

    property var settings

    spacing: ScreenTools.defaultFontPixelHeight / 2

    FlightPreparationSection {
        Layout.fillWidth: true
        title: qsTr("Review policy")
        description: qsTr("These thresholds affect this briefing only. They do not change vehicle parameters or arming checks.")
    }

    FlightPreparationThreshold {
        Layout.fillWidth: true
        label: qsTr("Minimum battery charge")
        fact: root.settings.minimumBatteryPercent
    }

    FlightPreparationThreshold {
        Layout.fillWidth: true
        label: qsTr("Minimum GPS satellites")
        fact: root.settings.minimumSatellites
    }

    FlightPreparationThreshold {
        Layout.fillWidth: true
        label: qsTr("Maximum GPS HDOP")
        fact: root.settings.maximumHdop
    }

    FlightPreparationThreshold {
        Layout.fillWidth: true
        label: qsTr("Maximum cumulative packet loss")
        fact: root.settings.maximumPacketLoss
    }

    FactCheckBox {
        text: qsTr("Require GPS")
        fact: root.settings.requireGps
    }

    QGCLabel {
        Layout.fillWidth: true
        text: qsTr("GPS is always checked when the vehicle reports that it requires a fix.")
        wrapMode: Text.WordWrap
    }

    FactCheckBox {
        text: qsTr("Require a home position")
        fact: root.settings.requireHome
    }

    FactCheckBox {
        text: qsTr("Require a loaded mission")
        fact: root.settings.requireMission
    }

    FactCheckBox {
        text: qsTr("Require a healthy RC receiver")
        fact: root.settings.requireRc
    }
}
