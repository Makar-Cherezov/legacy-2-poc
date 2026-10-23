import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls

import "FlightPreparationRules.js" as Rules

/// Reviews only the mission associated with the active Fly View controller.
ColumnLayout {
    id: root

    property var preparation
    readonly property bool available: preparation.live && preparation.snapshot.missionAvailable
                                     && preparation.snapshot.missionPresent
                                     && !preparation.snapshot.missionLoading
                                     && !preparation.snapshot.missionDirty

    spacing: ScreenTools.defaultFontPixelHeight / 2

    FlightPreparationSection {
        Layout.fillWidth: true
        title: qsTr("Loaded mission")
        description: qsTr("Review the route, altitude references, terrain clearance and final mission action in Plan View.")
    }

    FlightPreparationStatusCard {
        Layout.fillWidth: true
        result: {
            for (var i = 0; i < root.preparation.rows.length; ++i) {
                if (root.preparation.rows[i].key === "mission") {
                    return root.preparation.rows[i]
                }
            }
            return {title: qsTr("Mission"), level: "unknown", detail: qsTr("Waiting for mission information.")}
        }
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Mission commands")
        value: root.available ? root.preparation.snapshot.missionItems.toString() : qsTr("Unavailable")
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Calculated distance")
        value: root.available && Rules.inRange(root.preparation.snapshot.missionDistance, 0.01, 40000000)
               ? qsTr("%1 m").arg(root.preparation.snapshot.missionDistance.toFixed(0)) : qsTr("Unavailable")
    }

    FlightPreparationMetric {
        Layout.fillWidth: true
        label: qsTr("Calculated duration")
        value: root.available && Rules.inRange(root.preparation.snapshot.missionTime, 0.01, 604800)
               ? qsTr("%1 min").arg((root.preparation.snapshot.missionTime / 60).toFixed(1)) : qsTr("Unavailable")
    }

    QGCLabel {
        Layout.fillWidth: true
        text: qsTr("Calculated values may be unavailable in Fly View. They do not account for current wind, battery condition or emergency reserves.")
        wrapMode: Text.WordWrap
    }

    FlightPreparationPosition {
        Layout.fillWidth: true
        preparation: root.preparation
    }

    FlightPreparationSection {
        Layout.fillWidth: true
        title: qsTr("Route review")
        description: qsTr("Confirm takeoff and landing locations, airspace constraints, return height and the lost-link action before flight.")
    }
}
