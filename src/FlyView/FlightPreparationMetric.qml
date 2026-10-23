import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls

/// A wrapping name/value pair for telemetry and mission details.
RowLayout {
    id: root

    property string label
    property string value

    spacing: ScreenTools.defaultFontPixelWidth

    QGCLabel {
        text: root.label
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 24
    }

    QGCLabel {
        text: root.value
        textFormat: Text.PlainText
        wrapMode: Text.WrapAnywhere
        horizontalAlignment: Text.AlignRight
        Layout.fillWidth: true
        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 20
    }
}
