import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl.Controls

/// Session note and selectable, stable report snapshot; no automatic file writes.
ColumnLayout {
    id: root

    property var preparation

    spacing: ScreenTools.defaultFontPixelHeight / 2

    QGCPalette { id: qgcPal; colorGroupEnabled: root.enabled }

    FlightPreparationSection {
        Layout.fillWidth: true
        title: qsTr("Operator note")
        description: qsTr("Keep a short note for this review session. It is cleared with the site checks and is not saved automatically.")
    }

    TextArea {
        id: noteEditor
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(ScreenTools.defaultFontPixelHeight * 6, contentHeight + topPadding + bottomPadding)
        color: qgcPal.text
        selectionColor: qgcPal.buttonHighlight
        selectedTextColor: qgcPal.buttonHighlightText
        font.pointSize: ScreenTools.defaultFontPointSize
        wrapMode: TextEdit.Wrap
        selectByMouse: true
        enabled: root.preparation.live
        text: root.preparation.note
        placeholderText: qsTr("Location, payload, weather or other observations")
        onTextChanged: {
            // remove() keeps the text: binding to preparation.note intact, unlike assigning text
            if (length > 4000) {
                remove(4000, length)
                return
            }
            if (root.preparation.note !== text) {
                root.preparation.note = text
            }
        }
        background: Rectangle { color: qgcPal.windowShade; border.color: qgcPal.text }
    }

    QGCLabel {
        Layout.fillWidth: true
        text: qsTr("%1 / 4000 characters").arg(noteEditor.length)
    }

    QGCButton {
        text: qsTr("Capture review report")
        onClicked: root.preparation.captureReport()
    }

    QGCLabel {
        Layout.fillWidth: true
        visible: root.preparation.report.length > 0
        text: qsTr("Snapshot captured at %1. Select the text to copy it; capture again to refresh.").arg(root.preparation.reportTime)
        wrapMode: Text.WordWrap
    }

    TextArea {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(ScreenTools.defaultFontPixelHeight * 16, contentHeight + topPadding + bottomPadding)
        visible: root.preparation.report.length > 0
        readOnly: true
        selectByMouse: true
        color: qgcPal.text
        selectionColor: qgcPal.buttonHighlight
        selectedTextColor: qgcPal.buttonHighlightText
        font.pointSize: ScreenTools.defaultFontPointSize
        text: root.preparation.report
        textFormat: TextEdit.PlainText
        wrapMode: TextEdit.Wrap
        background: Rectangle { color: qgcPal.windowShade; border.color: qgcPal.text }
    }
}
