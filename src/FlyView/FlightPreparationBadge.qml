import QtQuick

import QGroundControl.Controls

import "FlightPreparationRules.js" as Rules

/// Status indicator with text so meaning does not depend on colour.
Rectangle {
    id: root

    property string level: Rules.unknown
    readonly property color statusColor: level === Rules.warning ? qgcPal.warningText
                                         : (level === Rules.ok ? qgcPal.colorGreen : qgcPal.text)

    implicitWidth: statusText.implicitWidth + ScreenTools.defaultFontPixelWidth * 2
    implicitHeight: statusText.implicitHeight + ScreenTools.defaultFontPixelHeight * 0.5
    color: qgcPal.window
    border.width: 1
    border.color: statusColor
    radius: ScreenTools.defaultFontPixelWidth / 2

    QGCPalette { id: qgcPal; colorGroupEnabled: root.enabled }

    QGCLabel {
        id: statusText
        anchors.centerIn: parent
        text: Rules.label(root.level)
        color: root.statusColor
        font.bold: true
    }
}
