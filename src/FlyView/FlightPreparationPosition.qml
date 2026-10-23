import QtQuick
import QtQuick.Layouts

import "FlightPreparationRules.js" as Rules

/// Coordinate display preserves valid zero latitude and longitude.
ColumnLayout {
    id: root

    property var preparation

    FlightPreparationSection {
        Layout.fillWidth: true
        title: qsTr("Position and home")
        description: qsTr("Compare the home location with the map and the intended recovery site.")
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Vehicle latitude")
        value: root.preparation.live && Rules.inRange(root.preparation.snapshot.latitude, -90, 90)
               ? root.preparation.snapshot.latitude.toFixed(6) : qsTr("Unavailable")
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Vehicle longitude")
        value: root.preparation.live && Rules.inRange(root.preparation.snapshot.longitude, -180, 180)
               ? root.preparation.snapshot.longitude.toFixed(6) : qsTr("Unavailable")
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Home latitude")
        value: root.preparation.live && Rules.inRange(root.preparation.snapshot.homeLatitude, -90, 90)
               ? root.preparation.snapshot.homeLatitude.toFixed(6) : qsTr("Unavailable")
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Home longitude")
        value: root.preparation.live && Rules.inRange(root.preparation.snapshot.homeLongitude, -180, 180)
               ? root.preparation.snapshot.homeLongitude.toFixed(6) : qsTr("Unavailable")
    }
}
