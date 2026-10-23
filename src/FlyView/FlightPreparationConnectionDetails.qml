import QtQuick
import QtQuick.Layouts


/// Connection context; cumulative packet loss is not a real-time RSSI estimate.
ColumnLayout {
    id: root

    property var preparation

    spacing: ScreenTools.defaultFontPixelHeight / 3

    FlightPreparationSection {
        Layout.fillWidth: true
        title: qsTr("Connection details")
        description: qsTr("Packet loss is cumulative for this connection session.")
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Primary link")
        value: root.preparation.live ? root.preparation.snapshot.linkName : qsTr("Unavailable")
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Attached links")
        value: root.preparation.snapshot.connected ? root.preparation.snapshot.linkCount.toString() : qsTr("Unavailable")
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Flight mode")
        value: root.preparation.live && root.preparation.snapshot.flightMode.length
               ? root.preparation.snapshot.flightMode : qsTr("Unavailable")
    }
}
