import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls

/// Section heading and optional explanation sized for narrow displays.
ColumnLayout {
    id: root

    property string title
    property string description

    spacing: ScreenTools.defaultFontPixelHeight / 3

    QGCLabel {
        text: root.title
        font.bold: true
        font.pointSize: ScreenTools.mediumFontPointSize
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    QGCLabel {
        text: root.description
        visible: root.description.length > 0
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
