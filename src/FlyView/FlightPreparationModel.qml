import QtQuick

import "FlightPreparationSnapshot.js" as Snapshot
import "FlightPreparationRules.js" as Rules
import "FlightPreparationChecklist.js" as Checklist
import "FlightPreparationReport.js" as Report

/// Owns the active vehicle's review session; never mutates vehicle state.
Item {
    id: root

    property var vehicle: null
    property var missionController: null
    property var settings: null
    property var checkedItems: ({})
    property string note: ""
    property string report: ""
    property string reportTime: ""

    readonly property var snapshot: Snapshot.capture(vehicle, missionController)
    readonly property var policy: settings ? {
        minimumBatteryPercent: settings.minimumBatteryPercent.rawValue,
        minimumSatellites: settings.minimumSatellites.rawValue,
        maximumHdop: settings.maximumHdop.rawValue,
        maximumPacketLoss: settings.maximumPacketLoss.rawValue,
        requireGps: settings.requireGps.rawValue,
        requireHome: settings.requireHome.rawValue,
        requireMission: settings.requireMission.rawValue,
        requireRc: settings.requireRc.rawValue
    } : null
    readonly property var rows: policy ? Rules.evaluate(snapshot, policy) : []
    readonly property var summary: Rules.summarize(rows)
    readonly property var attentionRows: Rules.attentionRows(rows)
    readonly property var checks: Checklist.items()
    readonly property int completedChecks: Checklist.completed(checks, checkedItems)
    readonly property bool live: snapshot.connected && !snapshot.linkLost && snapshot.linkMonitoring
    readonly property bool armed: snapshot.armed

    onVehicleChanged: resetSession()
    onLiveChanged: {
        if (!live) {
            resetSession()
        }
    }
    onArmedChanged: {
        if (!armed) {
            resetSession()
        }
    }

    /// Changes only a known manual check; disconnected sessions cannot be signed off.
    function setChecked(key, checked) {
        if (!live) {
            return
        }
        var next = {}
        for (var i = 0; i < checks.length; ++i) {
            var itemKey = checks[i].key
            next[itemKey] = itemKey === key ? checked === true : checkedItems[itemKey] === true
        }
        checkedItems = next
    }

    /// Starts a new review without changing thresholds or the vehicle checklist.
    function resetSession() {
        checkedItems = {}
        note = ""
        report = ""
        reportTime = ""
    }

    /// Captures a report once so live telemetry does not disturb text selection.
    function captureReport() {
        reportTime = new Date().toISOString()
        report = Report.create(snapshot, rows, checks, checkedItems, note, reportTime)
    }
}
