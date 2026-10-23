.pragma library

var unknown = "unknown"
var warning = "warning"
var ok = "ok"
var info = "info"

/// Checks an inclusive range without accepting null, strings or NaN.
function inRange(value, minimum, maximum) {
    return typeof value === "number" && isFinite(value) && value >= minimum && value <= maximum
}

/// Provides a stable result shape for the briefing, filters and reports.
function row(key, title, level, detail) {
    return { key: key, title: title, level: level, detail: detail }
}

/// Returns translated status text independently of presentation colours.
function label(level) {
    switch (level) {
    case ok: return qsTranslate("FlightPreparation", "OK")
    case warning: return qsTranslate("FlightPreparation", "Attention")
    case info: return qsTranslate("FlightPreparation", "Information")
    default: return qsTranslate("FlightPreparation", "Unknown")
    }
}

/// Evaluates battery telemetry without letting a healthy battery mask a failure.
function batteryResult(battery, index, policy) {
    var id = inRange(battery.id, 0, 255) ? battery.id : index
    var title = qsTranslate("FlightPreparation", "Battery %1").arg(id)
    if (!battery.available) {
        return row("battery-" + index, title, unknown, qsTranslate("FlightPreparation", "Battery telemetry has not arrived."))
    }
    // MAV_BATTERY_CHARGE_STATE: LOW, CRITICAL, EMERGENCY, FAILED, UNHEALTHY.
    if (inRange(battery.chargeState, 2, 6)) {
        return row("battery-" + index, title, warning, qsTranslate("FlightPreparation", "The battery reports a low charge or a fault."))
    }
    if (!inRange(battery.percent, 0, 100)) {
        return row("battery-" + index, title, unknown, qsTranslate("FlightPreparation", "Remaining charge is unavailable."))
    }
    if (battery.percent < policy.minimumBatteryPercent) {
        return row("battery-" + index, title, warning,
                   qsTranslate("FlightPreparation", "%1% remaining; review minimum is %2%.").arg(battery.percent.toFixed(0)).arg(policy.minimumBatteryPercent))
    }
    return row("battery-" + index, title, ok,
               qsTranslate("FlightPreparation", "%1% remaining.").arg(battery.percent.toFixed(0)))
}

/// Evaluates a normalized snapshot. Cached telemetry cannot pass after link loss.
function evaluate(data, policy) {
    var results = []
    var connectionTitle = qsTranslate("FlightPreparation", "Connection")
    var live = data.connected && !data.linkLost && data.linkMonitoring
    if (!data.connected) {
        results.push(row("connection", connectionTitle, unknown, qsTranslate("FlightPreparation", "Connect a vehicle to receive telemetry.")))
    } else if (data.linkLost) {
        results.push(row("connection", connectionTitle, warning, qsTranslate("FlightPreparation", "Communication lost. Displayed values may be stale.")))
    } else if (!data.linkMonitoring) {
        results.push(row("connection", connectionTitle, unknown, qsTranslate("FlightPreparation", "Connection loss detection is disabled.")))
    } else if (!inRange(data.packetLoss, 0, 100)) {
        results.push(row("connection", connectionTitle, unknown, qsTranslate("FlightPreparation", "Packet loss information is unavailable.")))
    } else {
        results.push(row("connection", connectionTitle,
                         data.packetLoss > policy.maximumPacketLoss ? warning : ok,
                         qsTranslate("FlightPreparation", "%1% cumulative packet loss.").arg(data.packetLoss.toFixed(1))))
    }

    var unavailable = qsTranslate("FlightPreparation", "Waiting for a monitored, live connection.")
    var parametersTitle = qsTranslate("FlightPreparation", "Parameters")
    if (!live) {
        results.push(row("parameters", parametersTitle, unknown, unavailable))
    } else if (data.missingParameters) {
        results.push(row("parameters", parametersTitle, warning, qsTranslate("FlightPreparation", "Some vehicle parameters are missing.")))
    } else if (!data.parametersReady || !data.initialConnectComplete) {
        results.push(row("parameters", parametersTitle, unknown, qsTranslate("FlightPreparation", "Initial vehicle data is still loading.")))
    } else if (data.pendingWrites) {
        results.push(row("parameters", parametersTitle, warning, qsTranslate("FlightPreparation", "Parameter changes are awaiting confirmation.")))
    } else {
        results.push(row("parameters", parametersTitle, ok, qsTranslate("FlightPreparation", "Parameters received; no pending writes.")))
    }

    var setupTitle = qsTranslate("FlightPreparation", "Vehicle setup")
    results.push(row("setup", setupTitle,
                     !live || !data.parametersReady ? unknown : (data.setupComplete ? ok : warning),
                     !live ? unavailable : (!data.parametersReady ? qsTranslate("FlightPreparation", "Waiting for parameters.")
                     : (data.setupComplete ? qsTranslate("FlightPreparation", "Required vehicle setup is complete.")
                     : qsTranslate("FlightPreparation", "Open Vehicle Setup to complete configuration.")))))

    var batteryTitle = qsTranslate("FlightPreparation", "Battery")
    if (!live || !data.batteries.length) {
        results.push(row("battery", batteryTitle, unknown,
                         !live ? unavailable : qsTranslate("FlightPreparation", "No battery telemetry is available.")))
    } else {
        for (var i = 0; i < data.batteries.length; ++i) {
            results.push(batteryResult(data.batteries[i], i, policy))
        }
    }

    var gpsTitle = qsTranslate("FlightPreparation", "GPS")
    if (!live) {
        results.push(row("gps", gpsTitle, unknown, unavailable))
    } else if (!policy.requireGps && !data.gpsRequired) {
        results.push(row("gps", gpsTitle, info, qsTranslate("FlightPreparation", "GPS is not required by the current review policy or vehicle.")))
    } else if (!data.gpsAvailable || !inRange(data.gpsFix, 0, 8)) {
        results.push(row("gps", gpsTitle, unknown, qsTranslate("FlightPreparation", "GPS telemetry is unavailable.")))
    } else if (data.gpsFix < 3) {
        results.push(row("gps", gpsTitle, warning, qsTranslate("FlightPreparation", "Waiting for a 3D GPS fix.")))
    } else if (!inRange(data.satellites, 0, 254) || !inRange(data.hdop, 0.01, 655.34)) {
        results.push(row("gps", gpsTitle, unknown, qsTranslate("FlightPreparation", "Satellite count or HDOP is unavailable.")))
    } else {
        results.push(row("gps", gpsTitle,
                         data.satellites < policy.minimumSatellites || data.hdop > policy.maximumHdop ? warning : ok,
                         qsTranslate("FlightPreparation", "%1 satellites; HDOP %2.").arg(data.satellites).arg(data.hdop.toFixed(2))))
    }

    var homeTitle = qsTranslate("FlightPreparation", "Home position")
    results.push(row("home", homeTitle,
                     !live ? unknown : (!policy.requireHome ? info : (data.homeValid ? ok : warning)),
                     !live ? unavailable : (data.homeValid ? qsTranslate("FlightPreparation", "A home coordinate is available. Verify its location.")
                     : (policy.requireHome ? qsTranslate("FlightPreparation", "The vehicle has not reported a home position.")
                     : qsTranslate("FlightPreparation", "A home position is not required by the review policy.")))))

    var sensorTitle = qsTranslate("FlightPreparation", "Sensors")
    results.push(row("sensors", sensorTitle,
                     !live || !data.enabledSensors ? unknown : (data.unhealthySensors ? warning : ok),
                     !live ? unavailable : (!data.enabledSensors ? qsTranslate("FlightPreparation", "Sensor status is unavailable.")
                     : (data.unhealthySensors ? qsTranslate("FlightPreparation", "An enabled sensor reports a fault. Review vehicle messages.")
                     : qsTranslate("FlightPreparation", "Enabled sensors report healthy status.")))))

    var rcTitle = qsTranslate("FlightPreparation", "RC receiver")
    results.push(row("rc", rcTitle,
                     !live ? unknown : (!policy.requireRc ? info : (!data.rcPresent ? unknown : (data.rcEnabled && data.rcHealthy ? ok : warning))),
                     !live ? unavailable : (!policy.requireRc ? qsTranslate("FlightPreparation", "RC status is not required by the review policy.")
                     : (!data.rcPresent ? qsTranslate("FlightPreparation", "The autopilot has not reported an RC receiver.")
                     : (data.rcEnabled && data.rcHealthy ? qsTranslate("FlightPreparation", "The receiver reports healthy status. Perform the manual range check.")
                     : qsTranslate("FlightPreparation", "The receiver is disabled or reports a fault."))))))

    var missionTitle = qsTranslate("FlightPreparation", "Mission")
    if (!live || !data.missionAvailable) {
        results.push(row("mission", missionTitle, unknown, !live ? unavailable : qsTranslate("FlightPreparation", "Mission information is unavailable.")))
    } else if (data.missionLoading) {
        results.push(row("mission", missionTitle, unknown, qsTranslate("FlightPreparation", "Mission transfer is in progress.")))
    } else if (data.missionDirty) {
        results.push(row("mission", missionTitle, warning, qsTranslate("FlightPreparation", "The displayed mission has unsynchronized changes.")))
    } else if (!data.missionPresent) {
        results.push(row("mission", missionTitle, policy.requireMission ? warning : info,
                         qsTranslate("FlightPreparation", "No mission is loaded.")))
    } else {
        results.push(row("mission", missionTitle, ok, qsTranslate("FlightPreparation", "A mission is loaded. Review the route and return procedure.")))
    }

    var autopilotTitle = qsTranslate("FlightPreparation", "Autopilot readiness")
    results.push(row("autopilot", autopilotTitle,
                     !live || !data.readyAvailable ? unknown : (data.ready ? ok : warning),
                     !live ? unavailable : (!data.readyAvailable ? qsTranslate("FlightPreparation", "This firmware does not expose a readiness result.")
                     : (data.ready ? qsTranslate("FlightPreparation", "The autopilot reports ready. Operator checks still apply.")
                     : qsTranslate("FlightPreparation", "The autopilot is not ready. Review its arming messages.")))))
    return results
}

/// Counts categories; informational rows do not increase the passed count.
function summarize(rows) {
    var result = { ok: 0, warning: 0, unknown: 0, info: 0 }
    for (var i = 0; i < rows.length; ++i) {
        if (result[rows[i].level] !== undefined) {
            result[rows[i].level] += 1
        }
    }
    return result
}

/// Returns attention/unknown rows while preserving their diagnostic order.
function attentionRows(rows) {
    return rows.filter(function(item) { return item.level === warning || item.level === unknown })
}
