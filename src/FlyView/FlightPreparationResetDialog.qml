import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import QGroundControl.Controls

/// Confirms clearing operator work while retaining persistent review thresholds.
QGCPopupDialog {
    title: qsTr("Start a new review")
    buttons: Dialog.Reset | Dialog.Cancel

    property var preparation

    onAccepted: preparation.resetSession()

    QGCLabel {
        width: Math.min(ScreenTools.defaultFontPixelWidth * 48, mainWindow.width * 0.8)
        text: qsTr("Clear the site checks, operator note and captured report? Review thresholds will be retained.")
        wrapMode: Text.WordWrap
    }
}
