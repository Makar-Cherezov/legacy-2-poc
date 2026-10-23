.pragma library

/// Policy matching FlightPreparation.SettingsGroup.json defaults.
function defaultPolicy() {
    return {
        minimumBatteryPercent: 40,
        minimumSatellites: 8,
        maximumHdop: 2,
        maximumPacketLoss: 10,
        requireGps: true,
        requireHome: true,
        requireMission: false,
        requireRc: false
    }
}

function battery(overrides) {
    var result = { id: 0, available: true, percent: 80, voltage: 16.4, temperature: 25, chargeState: 1 }
    return merge(result, overrides)
}

/// Snapshot of a connected, healthy vehicle that passes every default check.
function healthySnapshot(overrides) {
    var result = {
        connected: true,
        vehicleId: 1,
        linkLost: false,
        linkMonitoring: true,
        linkName: "UDP",
        linkCount: 1,
        packetLoss: 1.5,
        initialConnectComplete: true,
        parametersReady: true,
        missingParameters: false,
        pendingWrites: false,
        setupComplete: true,
        armed: false,
        flying: false,
        flightMode: "Position",
        readyAvailable: true,
        ready: true,
        gpsRequired: true,
        gpsAvailable: true,
        gpsFix: 3,
        satellites: 12,
        hdop: 0.8,
        homeValid: true,
        latitude: 47.3977419,
        longitude: 8.5455939,
        homeLatitude: 47.3977419,
        homeLongitude: 8.5455939,
        enabledSensors: 65536 | 1,
        unhealthySensors: 0,
        rcPresent: true,
        rcEnabled: true,
        rcHealthy: true,
        rcRssi: 90,
        batteries: [battery()],
        missionAvailable: true,
        missionLoading: false,
        missionDirty: false,
        missionPresent: true,
        missionItems: 5,
        missionDistance: 1200,
        missionTime: 300,
        missionIndex: 0
    }
    return merge(result, overrides)
}

function merge(target, overrides) {
    if (overrides) {
        for (var key in overrides) {
            target[key] = overrides[key]
        }
    }
    return target
}

function find(rows, key) {
    for (var i = 0; i < rows.length; ++i) {
        if (rows[i].key === key) {
            return rows[i]
        }
    }
    return null
}

function fact(value) {
    return { rawValue: value }
}
