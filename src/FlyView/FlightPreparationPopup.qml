import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl.Controls

/// Read-only vehicle briefing with session state owned by Fly View.
QGCPopupDialog {
    id: root
    title: qsTr("Flight preparation")
    buttons: Dialog.Close

    property var preparation
    property int currentPage: 0

    Component {
        id: resetDialog
        FlightPreparationResetDialog { preparation: root.preparation }
    }

    ColumnLayout {
        width: Math.min(ScreenTools.defaultFontPixelWidth * 66, mainWindow.width * 0.85)
        spacing: ScreenTools.defaultFontPixelHeight / 2

        FlightPreparationSummary {
            Layout.fillWidth: true
            preparation: root.preparation
        }

        Flow {
            Layout.fillWidth: true
            spacing: ScreenTools.defaultFontPixelWidth / 2

            Repeater {
                model: [qsTr("Overview"), qsTr("Site checks"), qsTr("Mission"), qsTr("Notes"), qsTr("Settings")]

                QGCButton {
                    text: modelData
                    checked: root.currentPage === index
                    onClicked: root.currentPage = index
                }
            }
        }

        FlightPreparationOverview {
            Layout.fillWidth: true
            visible: root.currentPage === 0
            preparation: root.preparation
        }

        FlightPreparationSiteChecks {
            Layout.fillWidth: true
            visible: root.currentPage === 1
            preparation: root.preparation
        }

        FlightPreparationMission {
            Layout.fillWidth: true
            visible: root.currentPage === 2
            preparation: root.preparation
        }

        FlightPreparationNotes {
            Layout.fillWidth: true
            visible: root.currentPage === 3
            preparation: root.preparation
        }

        FlightPreparationSettingsView {
            Layout.fillWidth: true
            visible: root.currentPage === 4
            settings: root.preparation.settings
        }

        QGCButton {
            text: qsTr("Start a new review")
            enabled: root.preparation.completedChecks > 0 || root.preparation.note.length > 0 || root.preparation.report.length > 0
            onClicked: resetDialog.createObject(mainWindow).open()
        }
    }
}
