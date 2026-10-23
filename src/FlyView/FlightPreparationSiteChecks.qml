import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls

/// Session acknowledgements independent of the enforced preflight checklist.
ColumnLayout {
    id: root

    property var preparation

    spacing: ScreenTools.defaultFontPixelHeight / 2

    FlightPreparationSection {
        Layout.fillWidth: true
        title: qsTr("Site checks")
        description: qsTr("Confirm these items after inspection. They reset on vehicle change, connection loss or disarming.")
    }

    Repeater {
        model: root.preparation.checks

        FlightPreparationManualCheck {
            Layout.fillWidth: true
            check: modelData
            reviewed: root.preparation.checkedItems[modelData.key] === true
            enabled: root.preparation.live
            onToggled: root.preparation.setChecked(modelData.key, reviewed)
        }
    }

    QGCLabel {
        Layout.fillWidth: true
        text: qsTr("These acknowledgements do not complete the vehicle's existing preflight checklist.")
        wrapMode: Text.WordWrap
    }
}
