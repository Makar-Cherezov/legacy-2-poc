import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls
import QGroundControl.FactControls

/// Bound numeric policy field; Fact validation enforces the metadata limits.
RowLayout {
    id: root

    property var fact
    property string label

    spacing: ScreenTools.defaultFontPixelWidth

    QGCLabel {
        text: root.label
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    FactTextField {
        fact: root.fact
        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 12
    }
}
