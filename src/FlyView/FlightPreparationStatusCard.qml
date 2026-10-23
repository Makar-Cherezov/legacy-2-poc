import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls

/// Wrapped diagnostic row shared by the overview and mission review.
Rectangle {
    id: root

    property var result: ({title: "", detail: "", level: "unknown"})

    implicitHeight: content.implicitHeight + ScreenTools.defaultFontPixelHeight
    color: qgcPal.windowShade
    radius: ScreenTools.defaultFontPixelWidth / 2

    QGCPalette { id: qgcPal; colorGroupEnabled: root.enabled }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: ScreenTools.defaultFontPixelHeight / 2
        spacing: ScreenTools.defaultFontPixelHeight / 3

        RowLayout {
            Layout.fillWidth: true

            QGCLabel {
                text: root.result.title
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            FlightPreparationBadge {
                level: root.result.level
            }
        }

        QGCLabel {
            text: root.result.detail
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            Layout.fillWidth: true
        }
    }
}
