import QtQuick
import QtTest

import "../../../../src/FlyView/FlightPreparationSnapshot.js" as Snapshot
import "FlightPreparationFixtures.js" as Fixtures

TestCase {
    name: "FlightPreparationSnapshot"

    readonly property int rcReceiverBit: 65536

    function batteryList(batteries) {
        return { count: batteries.length, get: function(index) { return batteries[index] } }
    }

    function vehicle(overrides) {
        var result = {
            id: 3,
            vehicleLinkManager: { communicationLost: false, communicationLostEnabled: true, primaryLinkName: "UDP", linkNames: ["UDP", "Serial"] },
            mavlinkLossPercent: 2.5,
            initialConnectComplete: true,
            parameterManager: { parametersReady: true, missingParameters: false, pendingWrites: false },
            autopilotPlugin: { setupComplete: true },
            armed: false,
            flying: false,
            flightMode: "Position",
            readyToFlyAvailable: true,
            readyToFly: true,
            requiresGpsFix: true,
            gps: { telemetryAvailable: true, lock: Fixtures.fact(3), count: Fixtures.fact(11), hdop: Fixtures.fact(0.9) },
            homePosition: { isValid: true, latitude: 47.1, longitude: 8.1 },
            coordinate: { isValid: true, latitude: 47.2, longitude: 8.2 },
            sensorsPresentBits: rcReceiverBit | 3,
            sensorsEnabledBits: rcReceiverBit | 1,
            sensorsHealthBits: rcReceiverBit | 1,
            sensorsUnhealthyBits: 2,
            rcRSSI: Fixtures.fact(80),
            batteries: batteryList([{
                id: Fixtures.fact(0), telemetryAvailable: true, percentRemaining: Fixtures.fact(75),
                voltage: Fixtures.fact(16.2), temperature: Fixtures.fact(30), chargeState: Fixtures.fact(1)
            }])
        }
        return Fixtures.merge(result, overrides)
    }

    function mission() {
        return { syncInProgress: false, dirty: false, containsItems: true,
                 visualItems: { count: 5 }, missionTotalDistance: 900, missionTime: 240, currentMissionIndex: 2 }
    }

    function test_factValue_data() {
        return [
            { tag: "null fact",     fact: null,                     expected: NaN },
            { tag: "number",        fact: Fixtures.fact(4.5),       expected: 4.5 },
            { tag: "zero",          fact: Fixtures.fact(0),         expected: 0 },
            { tag: "NaN",           fact: Fixtures.fact(NaN),       expected: NaN },
            { tag: "Infinity",      fact: Fixtures.fact(Infinity),  expected: NaN },
            { tag: "string",        fact: Fixtures.fact("4"),       expected: NaN },
            { tag: "boolean",       fact: Fixtures.fact(true),      expected: NaN }
        ]
    }

    function test_factValue(data) {
        var value = Snapshot.factValue(data.fact)
        if (isNaN(data.expected)) {
            verify(isNaN(value))
        } else {
            compare(value, data.expected)
        }
    }

    function test_noVehicle() {
        var data = Snapshot.capture(null, null)
        compare(data.connected, false)
        compare(data.vehicleId, -1)
        compare(data.linkLost, true)
        compare(data.linkMonitoring, false)
        compare(data.linkCount, 0)
        verify(isNaN(data.packetLoss))
        compare(data.gpsAvailable, false)
        verify(isNaN(data.gpsFix))
        verify(isNaN(data.latitude))
        compare(data.enabledSensors, 0)
        compare(data.rcPresent, false)
        compare(data.rcEnabled, false)
        compare(data.batteries, [])
        compare(data.missionAvailable, false)
        compare(data.missionItems, 0)
        compare(data.missionIndex, -1)
    }

    function test_connectedVehicle() {
        var data = Snapshot.capture(vehicle(), mission())
        compare(data.connected, true)
        compare(data.vehicleId, 3)
        compare(data.linkLost, false)
        compare(data.linkMonitoring, true)
        compare(data.linkName, "UDP")
        compare(data.linkCount, 2)
        compare(data.packetLoss, 2.5)
        compare(data.parametersReady, true)
        compare(data.setupComplete, true)
        compare(data.gpsRequired, true)
        compare(data.gpsAvailable, true)
        compare(data.gpsFix, 3)
        compare(data.satellites, 11)
        compare(data.hdop, 0.9)
        compare(data.homeValid, true)
        compare(data.latitude, 47.2)
        compare(data.homeLongitude, 8.1)
        compare(data.missionAvailable, true)
        compare(data.missionItems, 4)
        compare(data.missionDistance, 900)
        compare(data.missionTime, 240)
        compare(data.missionIndex, 2)
        compare(data.rcRssi, 80)
    }

    function test_sensorMasks() {
        var data = Snapshot.capture(vehicle(), null)
        compare(data.enabledSensors, rcReceiverBit | 1)
        compare(data.unhealthySensors, 0, "unhealthy bit of a disabled sensor must be ignored")
        compare(data.rcPresent, true)
        compare(data.rcEnabled, true)
        compare(data.rcHealthy, true)

        data = Snapshot.capture(vehicle({ sensorsUnhealthyBits: 1, sensorsHealthBits: 1 }), null)
        compare(data.unhealthySensors, 1)
        compare(data.rcHealthy, false)
    }

    function test_rcEnabledRequiresPresence() {
        var data = Snapshot.capture(vehicle({ sensorsPresentBits: 1, sensorsEnabledBits: rcReceiverBit | 1 }), null)
        compare(data.rcPresent, false)
        compare(data.rcEnabled, false)
    }

    function test_invalidCoordinatesBecomeNaN() {
        var data = Snapshot.capture(vehicle({
            coordinate: { isValid: false, latitude: 0, longitude: 0 },
            homePosition: { isValid: false, latitude: 0, longitude: 0 }
        }), null)
        compare(data.homeValid, false)
        verify(isNaN(data.latitude))
        verify(isNaN(data.longitude))
        verify(isNaN(data.homeLatitude))
        verify(isNaN(data.homeLongitude))
    }

    function test_zeroCoordinatesArePreserved() {
        var data = Snapshot.capture(vehicle({ coordinate: { isValid: true, latitude: 0, longitude: 0 } }), null)
        compare(data.latitude, 0)
        compare(data.longitude, 0)
    }

    function test_missingSubObjects() {
        var data = Snapshot.capture(vehicle({ vehicleLinkManager: null, parameterManager: null, gps: null, autopilotPlugin: null }), null)
        compare(data.connected, true)
        compare(data.linkLost, true)
        compare(data.linkMonitoring, false)
        compare(data.parametersReady, false)
        compare(data.setupComplete, false)
        compare(data.gpsAvailable, false)
        verify(isNaN(data.satellites))
    }

    function test_batteries() {
        var batteries = Snapshot.batteries(vehicle({ batteries: batteryList([
            { id: Fixtures.fact(1), telemetryAvailable: true, percentRemaining: Fixtures.fact(50),
              voltage: Fixtures.fact(12.1), temperature: Fixtures.fact(NaN), chargeState: Fixtures.fact(1) },
            { id: Fixtures.fact(2), telemetryAvailable: false, percentRemaining: null,
              voltage: Fixtures.fact(0), temperature: Fixtures.fact(20), chargeState: Fixtures.fact(5) }
        ]) }))
        compare(batteries.length, 2)
        compare(batteries[0].id, 1)
        compare(batteries[0].percent, 50)
        compare(batteries[0].voltage, 12.1)
        verify(isNaN(batteries[0].temperature))
        compare(batteries[1].available, false)
        verify(isNaN(batteries[1].percent))
        compare(batteries[1].chargeState, 5)
        compare(Snapshot.batteries(vehicle({ batteries: null })), [])
        compare(Snapshot.batteries(null), [])
    }

    function test_mission() {
        var data = Snapshot.capture(vehicle(), { syncInProgress: true, dirty: true, containsItems: false,
                                                 visualItems: { count: 1 }, missionTotalDistance: 0, missionTime: 0,
                                                 currentMissionIndex: -1 })
        compare(data.missionLoading, true)
        compare(data.missionDirty, true)
        compare(data.missionPresent, false)
        compare(data.missionItems, 0)
    }

    function test_missionItemCount_data() {
        return [
            { tag: "no mission",            mission: null,                                        expected: 0 },
            { tag: "no visual items",       mission: {},                                          expected: 0 },
            { tag: "non-numeric count",     mission: { visualItems: { count: "5" } },             expected: 0 },
            { tag: "settings item only",    mission: { visualItems: { count: 1 } },               expected: 0 },
            { tag: "empty list",            mission: { visualItems: { count: 0 } },               expected: 0 },
            { tag: "settings plus commands", mission: { visualItems: { count: 8 } },              expected: 7 }
        ]
    }

    function test_missionItemCount(data) {
        compare(Snapshot.missionItemCount(data.mission), data.expected)
    }

    function test_rcRssiIsFact() {
        verify(isNaN(Snapshot.capture(vehicle({ rcRSSI: 80 }), null).rcRssi))
        compare(Snapshot.capture(vehicle({ rcRSSI: Fixtures.fact(0) }), null).rcRssi, 0)
    }
}
