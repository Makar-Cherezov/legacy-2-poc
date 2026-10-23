import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls

/// Live automatic diagnostics with an optional attention-only filter.
ColumnLayout {
    id: root

    property var preparation
    property bool onlyAttention: false

    spacing: ScreenTools.defaultFontPixelHeight / 2

    QGCCheckBox {
        text: qsTr("Show only attention and unknown results")
        checked: root.onlyAttention
        onClicked: root.onlyAttention = checked
    }

    Repeater {
        model: root.onlyAttention ? root.preparation.attentionRows : root.preparation.rows

        FlightPreparationStatusCard {
            Layout.fillWidth: true
            result: modelData
        }
    }

    QGCLabel {
        Layout.fillWidth: true
        visible: root.onlyAttention && root.preparation.attentionRows.length === 0
        text: qsTr("No attention or unknown results in the automatic checks. Complete the site checks separately.")
        wrapMode: Text.WordWrap
    }

    FlightPreparationConnectionDetails {
        Layout.fillWidth: true
        preparation: root.preparation
    }

    FlightPreparationBatteryDetails {
        Layout.fillWidth: true
        preparation: root.preparation
    }
}
