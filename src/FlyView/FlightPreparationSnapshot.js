.pragma library

/// Returns a finite numeric Fact value, preserving unavailable values as NaN.
function factValue(fact) {
    if (!fact || typeof fact.rawValue !== "number" || !isFinite(fact.rawValue)) {
        return NaN
    }
    return fact.rawValue
}

/// Counts mission commands, excluding the leading mission settings item of the visual item list.
function missionItemCount(mission) {
    if (!mission || !mission.visualItems || typeof mission.visualItems.count !== "number") {
        return 0
    }
    return Math.max(0, mission.visualItems.count - 1)
}

/// Captures all batteries so an unhealthy secondary battery remains visible.
function batteries(vehicle) {
    var result = []
    if (!vehicle || !vehicle.batteries) {
        return result
    }
    for (var i = 0; i < vehicle.batteries.count; ++i) {
        var battery = vehicle.batteries.get(i)
        result.push({
            id: factValue(battery.id),
            available: battery.telemetryAvailable,
            percent: factValue(battery.percentRemaining),
            voltage: factValue(battery.voltage),
            temperature: factValue(battery.temperature),
            chargeState: factValue(battery.chargeState)
        })
    }
    return result
}

/// Normalizes telemetry without changing the vehicle, Facts or mission.
function capture(vehicle, mission) {
    var connected = !!vehicle
    var link = connected ? vehicle.vehicleLinkManager : null
    var parameters = connected ? vehicle.parameterManager : null
    var gps = connected ? vehicle.gps : null
    var enabledSensors = connected ? vehicle.sensorsEnabledBits & vehicle.sensorsPresentBits : 0
    return {
        connected: connected,
        vehicleId: connected ? vehicle.id : -1,
        linkLost: link ? link.communicationLost : true,
        linkMonitoring: link ? link.communicationLostEnabled : false,
        linkName: link ? link.primaryLinkName : "",
        linkCount: link ? link.linkNames.length : 0,
        packetLoss: connected ? vehicle.mavlinkLossPercent : NaN,
        initialConnectComplete: connected && vehicle.initialConnectComplete,
        parametersReady: parameters ? parameters.parametersReady : false,
        missingParameters: parameters ? parameters.missingParameters : false,
        pendingWrites: parameters ? parameters.pendingWrites : false,
        setupComplete: connected && vehicle.autopilotPlugin ? vehicle.autopilotPlugin.setupComplete : false,
        armed: connected && vehicle.armed,
        flying: connected && vehicle.flying,
        flightMode: connected ? vehicle.flightMode : "",
        readyAvailable: connected && vehicle.readyToFlyAvailable,
        ready: connected && vehicle.readyToFly,
        gpsRequired: connected && vehicle.requiresGpsFix,
        gpsAvailable: gps ? gps.telemetryAvailable : false,
        gpsFix: gps ? factValue(gps.lock) : NaN,
        satellites: gps ? factValue(gps.count) : NaN,
        hdop: gps ? factValue(gps.hdop) : NaN,
        homeValid: connected && vehicle.homePosition.isValid,
        latitude: connected && vehicle.coordinate.isValid ? vehicle.coordinate.latitude : NaN,
        longitude: connected && vehicle.coordinate.isValid ? vehicle.coordinate.longitude : NaN,
        homeLatitude: connected && vehicle.homePosition.isValid ? vehicle.homePosition.latitude : NaN,
        homeLongitude: connected && vehicle.homePosition.isValid ? vehicle.homePosition.longitude : NaN,
        enabledSensors: enabledSensors,
        unhealthySensors: connected ? vehicle.sensorsUnhealthyBits & enabledSensors : 0,
        rcPresent: connected && (vehicle.sensorsPresentBits & 65536) !== 0,
        rcEnabled: (enabledSensors & 65536) !== 0,
        rcHealthy: connected && (vehicle.sensorsHealthBits & 65536) !== 0,
        rcRssi: connected ? factValue(vehicle.rcRSSI) : NaN,
        batteries: batteries(vehicle),
        missionAvailable: !!mission,
        missionLoading: mission ? mission.syncInProgress : false,
        missionDirty: mission ? mission.dirty : false,
        missionPresent: mission ? mission.containsItems : false,
        missionItems: missionItemCount(mission),
        missionDistance: mission ? mission.missionTotalDistance : NaN,
        missionTime: mission ? mission.missionTime : NaN,
        missionIndex: mission ? mission.currentMissionIndex : -1
    }
}
