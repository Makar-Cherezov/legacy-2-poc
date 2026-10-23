import QtQuick
import QtTest

import "../../../../src/FlyView"

TestCase {
    name: "FlightPreparationModel"

    Component {
        id: settingsComponent
        QtObject {
            property QtObject minimumBatteryPercent:    QtObject { property var rawValue: 40 }
            property QtObject minimumSatellites:        QtObject { property var rawValue: 8 }
            property QtObject maximumHdop:              QtObject { property var rawValue: 2 }
            property QtObject maximumPacketLoss:        QtObject { property var rawValue: 10 }
            property QtObject requireGps:               QtObject { property var rawValue: true }
            property QtObject requireHome:              QtObject { property var rawValue: true }
            property QtObject requireMission:           QtObject { property var rawValue: false }
            property QtObject requireRc:                QtObject { property var rawValue: false }
        }
    }

    Component {
        id: vehicleComponent
        QtObject {
            property real   mavlinkLossPercent:     1
            property bool   initialConnectComplete: true
            property bool   armed:                  false
            property bool   flying:                 false
            property string flightMode:             "Position"
            property bool   readyToFlyAvailable:    true
            property bool   readyToFly:             true
            property bool   requiresGpsFix:         true
            property int    sensorsPresentBits:     65537
            property int    sensorsEnabledBits:     65537
            property int    sensorsHealthBits:      65537
            property int    sensorsUnhealthyBits:   0
            property var    rcRSSI:                 ({ rawValue: 0 })
            property var    homePosition:           ({ isValid: true, latitude: 47.1, longitude: 8.1 })
            property var    coordinate:             ({ isValid: true, latitude: 47.2, longitude: 8.2 })
            property var    batteries:              ({ count: 0, get: function() { return null } })
            property var    autopilotPlugin:        ({ setupComplete: true })
            property var    parameterManager:       ({ parametersReady: true, missingParameters: false, pendingWrites: false })

            property QtObject vehicleLinkManager: QtObject {
                property bool   communicationLost:          false
                property bool   communicationLostEnabled:   true
                property string primaryLinkName:            "UDP"
                property var    linkNames:                  ["UDP"]
            }

            property QtObject gps: QtObject {
                property bool       telemetryAvailable: true
                property QtObject   lock:               QtObject { property var rawValue: 3 }
                property QtObject   count:              QtObject { property var rawValue: 12 }
                property QtObject   hdop:               QtObject { property var rawValue: 0.8 }
            }
        }
    }

    Component {
        id: modelComponent
        FlightPreparationModel { }
    }

    function createModel(withVehicle) {
        var settings = createTemporaryObject(settingsComponent, this)
        var vehicle = withVehicle === false ? null : createTemporaryObject(vehicleComponent, this)
        var model = createTemporaryObject(modelComponent, this, { settings: settings, vehicle: vehicle })
        verify(model)
        return model
    }

    function row(model, key) {
        for (var i = 0; i < model.rows.length; ++i) {
            if (model.rows[i].key === key) {
                return model.rows[i]
            }
        }
        return null
    }

    function startSession(model) {
        model.setChecked("airframe", true)
        model.note = "Wind calm"
        model.captureReport()
        compare(model.completedChecks, 1)
        verify(model.report.length > 0)
    }

    function verifySessionCleared(model) {
        compare(model.completedChecks, 0)
        compare(model.checkedItems, {})
        compare(model.note, "")
        compare(model.report, "")
        compare(model.reportTime, "")
    }

    function test_noSettingsProducesNoRows() {
        var model = createTemporaryObject(modelComponent, this)
        compare(model.policy, null)
        compare(model.rows, [])
        compare(model.summary, { ok: 0, warning: 0, unknown: 0, info: 0 })
        compare(model.checks.length, 7)
    }

    function test_policyFollowsSettings() {
        var model = createModel()
        compare(model.policy.minimumBatteryPercent, 40)
        compare(model.policy.requireRc, false)
        compare(row(model, "rc").level, "info")

        model.settings.requireRc.rawValue = true
        compare(model.policy.requireRc, true)
        compare(row(model, "rc").level, "ok")
    }

    function test_rowsFollowTelemetry() {
        var model = createModel()
        compare(row(model, "connection").level, "ok")
        model.vehicle.mavlinkLossPercent = 25
        compare(row(model, "connection").level, "warning")
        model.vehicle.gps.lock.rawValue = 2
        compare(row(model, "gps").level, "warning")
    }

    function test_withoutVehicle() {
        var model = createModel(false)
        compare(model.live, false)
        compare(model.snapshot.connected, false)
        compare(row(model, "connection").level, "unknown")
        compare(model.summary.ok, 0)
    }

    function test_setCheckedRequiresLiveConnection() {
        var model = createModel(false)
        model.setChecked("airframe", true)
        compare(model.completedChecks, 0)
        compare(model.checkedItems, {})
    }

    function test_setChecked() {
        var model = createModel()
        model.setChecked("airframe", true)
        model.setChecked("area", true)
        compare(model.completedChecks, 2)
        model.setChecked("area", false)
        compare(model.completedChecks, 1)
        compare(model.checkedItems.airframe, true)
        compare(model.checkedItems.area, false)
    }

    function test_setCheckedIgnoresUnknownKeys() {
        var model = createModel()
        model.setChecked("airframe", true)
        model.setChecked("bogus", true)
        compare(model.completedChecks, 1)
        compare(model.checkedItems.bogus, undefined)
    }

    function test_setCheckedRequiresBooleanTrue() {
        var model = createModel()
        model.setChecked("airframe", "yes")
        compare(model.completedChecks, 0)
    }

    function test_resetSession() {
        var model = createModel()
        startSession(model)
        model.resetSession()
        verifySessionCleared(model)
        compare(model.settings.minimumBatteryPercent.rawValue, 40)
    }

    function test_vehicleChangeResetsSession() {
        var model = createModel()
        startSession(model)
        model.vehicle = createTemporaryObject(vehicleComponent, this, { flightMode: "Hold" })
        verifySessionCleared(model)
        compare(model.snapshot.flightMode, "Hold")
    }

    function test_linkLossResetsSession() {
        var model = createModel()
        startSession(model)
        model.vehicle.vehicleLinkManager.communicationLost = true
        compare(model.live, false)
        verifySessionCleared(model)
    }

    function test_disabledLossDetectionResetsSession() {
        var model = createModel()
        startSession(model)
        model.vehicle.vehicleLinkManager.communicationLostEnabled = false
        compare(model.live, false)
        verifySessionCleared(model)
    }

    function test_armingKeepsSessionAndDisarmingResetsIt() {
        var model = createModel()
        startSession(model)
        model.vehicle.armed = true
        compare(model.armed, true)
        compare(model.completedChecks, 1)
        compare(model.note, "Wind calm")

        model.vehicle.armed = false
        verifySessionCleared(model)
    }

    function test_captureReportIsStable() {
        var model = createModel()
        model.note = "Gusts expected"
        model.captureReport()
        verify(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/.test(model.reportTime))
        verify(model.report.indexOf("Captured: " + model.reportTime) !== -1)
        verify(model.report.indexOf("Gusts expected") !== -1)
        verify(model.report.indexOf("[OK] Connection") !== -1)

        var captured = model.report
        model.vehicle.mavlinkLossPercent = 50
        compare(row(model, "connection").level, "warning")
        compare(model.report, captured)
    }

    function test_modelDoesNotChangeVehicle() {
        var model = createModel()
        var vehicle = model.vehicle
        startSession(model)
        model.resetSession()
        compare(vehicle.armed, false)
        compare(vehicle.flightMode, "Position")
        compare(vehicle.mavlinkLossPercent, 1)
    }
}
