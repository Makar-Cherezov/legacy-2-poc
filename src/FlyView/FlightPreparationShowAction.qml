import QGroundControl
import QGroundControl.Controls

/// Opens the briefing even without a vehicle, allowing policy review.
ToolStripAction {
    text: qsTr("Preparation")
    iconSource: "/qmlimages/check.svg"
    visible: QGroundControl.settingsManager.flightPreparationSettings.userVisible
             && QGroundControl.settingsManager.flightPreparationSettings.showPreparation.rawValue
}
