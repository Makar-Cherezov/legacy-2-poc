import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist
    signal displayFlightPreparation

    model: [
        PreFlightCheckListShowAction { onTriggered: displayPreFlightChecklist() },
        FlightPreparationShowAction { onTriggered: displayFlightPreparation() },
        GuidedActionTakeoff { },
        GuidedActionLand { },
        GuidedActionRTL { },
        GuidedActionPause { },
        FlyViewAdditionalActionsButton { },
        GuidedToolStripAction {
            text:       _guidedController._customController.customButtonTitle
            iconSource: "/res/gear-white.svg"
            visible:    true
            enabled:    true
            actionID:   _guidedController._customController.actionCustomButton
        }
    ]
}
