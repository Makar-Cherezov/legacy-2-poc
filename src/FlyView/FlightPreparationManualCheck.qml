import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls

/// Manual acknowledgement with a separate wrapping label and explanation.
Rectangle {
    id: root

    property var check
    property bool reviewed: false
    signal toggled(bool reviewed)

    implicitHeight: content.implicitHeight + ScreenTools.defaultFontPixelHeight
    color: qgcPal.windowShade
    radius: ScreenTools.defaultFontPixelWidth / 2

    QGCPalette { id: qgcPal; colorGroupEnabled: root.enabled }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: ScreenTools.defaultFontPixelHeight / 2
        spacing: ScreenTools.defaultFontPixelWidth

        QGCCheckBox {
            checked: root.reviewed
            Accessible.name: root.check.title
            Layout.alignment: Qt.AlignTop
            onClicked: root.toggled(checked)
        }

        ColumnLayout {
            Layout.fillWidth: true

            QGCLabel {
                Layout.fillWidth: true
                text: root.check.title
                font.bold: true
                wrapMode: Text.WordWrap
            }

            QGCLabel {
                Layout.fillWidth: true
                text: root.check.detail
                wrapMode: Text.WordWrap
            }
        }
    }
}
