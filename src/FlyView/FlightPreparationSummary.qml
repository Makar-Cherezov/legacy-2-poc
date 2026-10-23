import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls

/// Summarizes observed checks without granting an arming or takeoff clearance.
ColumnLayout {
    id: root

    property var preparation

    spacing: ScreenTools.defaultFontPixelHeight / 2

    FlightPreparationSection {
        Layout.fillWidth: true
        title: !root.preparation.snapshot.connected ? qsTr("No vehicle connected")
               : qsTr("Vehicle %1").arg(root.preparation.snapshot.vehicleId)
        description: qsTr("This review supplements the preflight checklist and autopilot arming checks.")
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Automatic checks")
        value: qsTr("%1 OK · %2 attention · %3 unknown")
               .arg(root.preparation.summary.ok)
               .arg(root.preparation.summary.warning)
               .arg(root.preparation.summary.unknown)
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Site checks")
        value: qsTr("%1 of %2 reviewed").arg(root.preparation.completedChecks).arg(root.preparation.checks.length)
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Vehicle state")
        value: !root.preparation.live ? qsTr("Unavailable")
               : (root.preparation.snapshot.flying ? qsTr("Flying")
               : (root.preparation.armed ? qsTr("Armed") : qsTr("Disarmed")))
    }

    QGCLabel {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: !root.preparation.live ? qsTr("Waiting for a monitored connection. Cached telemetry cannot confirm readiness.")
              : (root.preparation.armed ? qsTr("Vehicle is armed. Review information without changing the current flight.")
              : qsTr("Review warnings, unknown values and site checks before using the normal flight controls."))
    }
}
