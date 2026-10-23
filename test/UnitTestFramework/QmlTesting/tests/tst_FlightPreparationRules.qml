import QtQuick
import QtTest

import "../../../../src/FlyView/FlightPreparationRules.js" as Rules
import "FlightPreparationFixtures.js" as Fixtures

TestCase {
    name: "FlightPreparationRules"

    function evaluate(snapshotOverrides, policyOverrides) {
        var policy = Fixtures.merge(Fixtures.defaultPolicy(), policyOverrides)
        return Rules.evaluate(Fixtures.healthySnapshot(snapshotOverrides), policy)
    }

    function levelOf(key, snapshotOverrides, policyOverrides) {
        var result = Fixtures.find(evaluate(snapshotOverrides, policyOverrides), key)
        verify(result !== null, "missing row " + key)
        return result.level
    }

    function test_inRange_data() {
        return [
            { tag: "lower bound",   value: 0,           expected: true },
            { tag: "upper bound",   value: 10,          expected: true },
            { tag: "below",         value: -0.1,        expected: false },
            { tag: "above",         value: 10.1,        expected: false },
            { tag: "NaN",           value: NaN,         expected: false },
            { tag: "Infinity",      value: Infinity,    expected: false },
            { tag: "null",          value: null,        expected: false },
            { tag: "undefined",     value: undefined,   expected: false },
            { tag: "numeric string", value: "5",        expected: false }
        ]
    }

    function test_inRange(data) {
        compare(Rules.inRange(data.value, 0, 10), data.expected)
    }

    function test_label() {
        compare(Rules.label(Rules.ok),      "OK")
        compare(Rules.label(Rules.warning), "Attention")
        compare(Rules.label(Rules.info),    "Information")
        compare(Rules.label(Rules.unknown), "Unknown")
        compare(Rules.label("bogus"),       "Unknown")
    }

    function test_healthyVehiclePassesAllChecks() {
        var rows = evaluate()
        var keys = rows.map(function(row) { return row.key })
        compare(keys, ["connection", "parameters", "setup", "battery-0", "gps", "home", "sensors", "rc", "mission", "autopilot"])
        for (var i = 0; i < rows.length; ++i) {
            var expected = rows[i].key === "rc" ? Rules.info : Rules.ok
            compare(rows[i].level, expected, rows[i].key)
            verify(rows[i].title.length > 0)
            verify(rows[i].detail.length > 0)
        }
    }

    function test_connection_data() {
        return [
            { tag: "disconnected",          snapshot: { connected: false },             expected: Rules.unknown },
            { tag: "link lost",             snapshot: { linkLost: true },               expected: Rules.warning },
            { tag: "monitoring disabled",   snapshot: { linkMonitoring: false },        expected: Rules.unknown },
            { tag: "loss unavailable",      snapshot: { packetLoss: NaN },              expected: Rules.unknown },
            { tag: "loss above 100",        snapshot: { packetLoss: 101 },              expected: Rules.unknown },
            { tag: "loss at threshold",     snapshot: { packetLoss: 10 },               expected: Rules.ok },
            { tag: "loss above threshold",  snapshot: { packetLoss: 10.1 },             expected: Rules.warning }
        ]
    }

    function test_connection(data) {
        compare(levelOf("connection", data.snapshot), data.expected)
    }

    function test_staleTelemetryCannotPass_data() {
        return [
            { tag: "disconnected",          snapshot: { connected: false } },
            { tag: "link lost",             snapshot: { linkLost: true } },
            { tag: "monitoring disabled",   snapshot: { linkMonitoring: false } }
        ]
    }

    function test_staleTelemetryCannotPass(data) {
        var rows = evaluate(data.snapshot)
        for (var i = 0; i < rows.length; ++i) {
            if (rows[i].key !== "connection") {
                compare(rows[i].level, Rules.unknown, rows[i].key)
            }
        }
        compare(Fixtures.find(rows, "battery").detail, "Waiting for a monitored, live connection.")
    }

    function test_parameters_data() {
        return [
            { tag: "missing",               snapshot: { missingParameters: true },          expected: Rules.warning },
            { tag: "not ready",             snapshot: { parametersReady: false },           expected: Rules.unknown },
            { tag: "initial connect",       snapshot: { initialConnectComplete: false },    expected: Rules.unknown },
            { tag: "pending writes",        snapshot: { pendingWrites: true },              expected: Rules.warning },
            { tag: "missing beats loading", snapshot: { missingParameters: true, parametersReady: false }, expected: Rules.warning }
        ]
    }

    function test_parameters(data) {
        compare(levelOf("parameters", data.snapshot), data.expected)
    }

    function test_setup_data() {
        return [
            { tag: "complete",              snapshot: { setupComplete: true },                          expected: Rules.ok },
            { tag: "incomplete",            snapshot: { setupComplete: false },                         expected: Rules.warning },
            { tag: "parameters not ready",  snapshot: { setupComplete: false, parametersReady: false }, expected: Rules.unknown }
        ]
    }

    function test_setup(data) {
        compare(levelOf("setup", data.snapshot), data.expected)
    }

    function test_battery_data() {
        return [
            { tag: "no telemetry",          battery: { available: false },              expected: Rules.unknown },
            { tag: "charge state low",      battery: { chargeState: 2 },                expected: Rules.warning },
            { tag: "charge state unhealthy", battery: { chargeState: 6 },               expected: Rules.warning },
            { tag: "charge state ok",       battery: { chargeState: 1 },                expected: Rules.ok },
            { tag: "charge state unknown",  battery: { chargeState: NaN },              expected: Rules.ok },
            { tag: "percent unavailable",   battery: { percent: NaN },                  expected: Rules.unknown },
            { tag: "percent out of range",  battery: { percent: 255 },                  expected: Rules.unknown },
            { tag: "below minimum",         battery: { percent: 39 },                   expected: Rules.warning },
            { tag: "at minimum",            battery: { percent: 40 },                   expected: Rules.ok },
            { tag: "fault beats charge",    battery: { percent: 100, chargeState: 4 },  expected: Rules.warning }
        ]
    }

    function test_battery(data) {
        var snapshot = { batteries: [Fixtures.battery(data.battery)] }
        compare(levelOf("battery-0", snapshot), data.expected)
    }

    function test_noBatteryTelemetry() {
        var rows = evaluate({ batteries: [] })
        var row = Fixtures.find(rows, "battery")
        compare(row.level, Rules.unknown)
        compare(row.detail, "No battery telemetry is available.")
        compare(Fixtures.find(rows, "battery-0"), null)
    }

    function test_healthyBatteryDoesNotMaskFailure() {
        var rows = evaluate({ batteries: [Fixtures.battery({ id: 1 }), Fixtures.battery({ id: 2, percent: 10 })] })
        compare(Fixtures.find(rows, "battery-0").level, Rules.ok)
        compare(Fixtures.find(rows, "battery-1").level, Rules.warning)
        compare(Fixtures.find(rows, "battery-1").title, "Battery 2")
        compare(Rules.summarize(rows).warning, 1)
    }

    function test_batteryTitleFallsBackToIndex() {
        var rows = evaluate({ batteries: [Fixtures.battery({ id: NaN })] })
        compare(Fixtures.find(rows, "battery-0").title, "Battery 0")
    }

    function test_batteryThresholdFollowsPolicy() {
        var snapshot = { batteries: [Fixtures.battery({ percent: 60 })] }
        compare(levelOf("battery-0", snapshot, { minimumBatteryPercent: 70 }), Rules.warning)
        compare(levelOf("battery-0", snapshot, { minimumBatteryPercent: 60 }), Rules.ok)
    }

    function test_gps_data() {
        return [
            { tag: "not required",          snapshot: { gpsRequired: false },   policy: { requireGps: false },  expected: Rules.info },
            { tag: "vehicle requires",      snapshot: { gpsRequired: true },    policy: { requireGps: false },  expected: Rules.ok },
            { tag: "policy requires",       snapshot: { gpsRequired: false },   policy: { requireGps: true },   expected: Rules.ok },
            { tag: "no telemetry",          snapshot: { gpsAvailable: false },  policy: {},                     expected: Rules.unknown },
            { tag: "fix unknown",           snapshot: { gpsFix: NaN },          policy: {},                     expected: Rules.unknown },
            { tag: "fix out of range",      snapshot: { gpsFix: 9 },            policy: {},                     expected: Rules.unknown },
            { tag: "2D fix",                snapshot: { gpsFix: 2 },            policy: {},                     expected: Rules.warning },
            { tag: "satellites unknown",    snapshot: { satellites: NaN },      policy: {},                     expected: Rules.unknown },
            { tag: "hdop unknown",          snapshot: { hdop: NaN },            policy: {},                     expected: Rules.unknown },
            { tag: "hdop zero",             snapshot: { hdop: 0 },              policy: {},                     expected: Rules.unknown },
            { tag: "few satellites",        snapshot: { satellites: 7 },        policy: {},                     expected: Rules.warning },
            { tag: "minimum satellites",    snapshot: { satellites: 8 },        policy: {},                     expected: Rules.ok },
            { tag: "zero satellites",       snapshot: { satellites: 0 },        policy: {},                     expected: Rules.warning },
            { tag: "high hdop",             snapshot: { hdop: 2.01 },           policy: {},                     expected: Rules.warning },
            { tag: "maximum hdop",          snapshot: { hdop: 2 },              policy: {},                     expected: Rules.ok },
            { tag: "RTK fixed",             snapshot: { gpsFix: 6 },            policy: {},                     expected: Rules.ok }
        ]
    }

    function test_gps(data) {
        compare(levelOf("gps", data.snapshot, data.policy), data.expected)
    }

    function test_gpsDetail() {
        compare(Fixtures.find(evaluate({ satellites: 12, hdop: 0.8 }), "gps").detail, "12 satellites; HDOP 0.80.")
    }

    function test_home_data() {
        return [
            { tag: "valid",                 snapshot: { homeValid: true },  policy: { requireHome: true },  expected: Rules.ok },
            { tag: "missing",               snapshot: { homeValid: false }, policy: { requireHome: true },  expected: Rules.warning },
            { tag: "not required",          snapshot: { homeValid: false }, policy: { requireHome: false }, expected: Rules.info },
            { tag: "not required but valid", snapshot: { homeValid: true }, policy: { requireHome: false }, expected: Rules.info }
        ]
    }

    function test_home(data) {
        compare(levelOf("home", data.snapshot, data.policy), data.expected)
    }

    function test_sensors_data() {
        return [
            { tag: "healthy",               snapshot: { enabledSensors: 1, unhealthySensors: 0 },   expected: Rules.ok },
            { tag: "unhealthy",             snapshot: { enabledSensors: 1, unhealthySensors: 1 },   expected: Rules.warning },
            { tag: "status unavailable",    snapshot: { enabledSensors: 0, unhealthySensors: 0 },   expected: Rules.unknown }
        ]
    }

    function test_sensors(data) {
        compare(levelOf("sensors", data.snapshot), data.expected)
    }

    function test_rc_data() {
        return [
            { tag: "not required",  snapshot: { rcHealthy: false },                     policy: { requireRc: false },   expected: Rules.info },
            { tag: "healthy",       snapshot: {},                                       policy: { requireRc: true },    expected: Rules.ok },
            { tag: "not present",   snapshot: { rcPresent: false },                     policy: { requireRc: true },    expected: Rules.unknown },
            { tag: "disabled",      snapshot: { rcEnabled: false },                     policy: { requireRc: true },    expected: Rules.warning },
            { tag: "unhealthy",     snapshot: { rcHealthy: false },                     policy: { requireRc: true },    expected: Rules.warning }
        ]
    }

    function test_rc(data) {
        compare(levelOf("rc", data.snapshot, data.policy), data.expected)
    }

    function test_mission_data() {
        return [
            { tag: "controller missing",    snapshot: { missionAvailable: false },  policy: {},                         expected: Rules.unknown },
            { tag: "loading",               snapshot: { missionLoading: true },     policy: {},                         expected: Rules.unknown },
            { tag: "dirty",                 snapshot: { missionDirty: true },       policy: {},                         expected: Rules.warning },
            { tag: "loading beats dirty",   snapshot: { missionLoading: true, missionDirty: true }, policy: {},         expected: Rules.unknown },
            { tag: "absent optional",       snapshot: { missionPresent: false },    policy: { requireMission: false },  expected: Rules.info },
            { tag: "absent required",       snapshot: { missionPresent: false },    policy: { requireMission: true },   expected: Rules.warning },
            { tag: "loaded",                snapshot: {},                           policy: { requireMission: true },   expected: Rules.ok }
        ]
    }

    function test_mission(data) {
        compare(levelOf("mission", data.snapshot, data.policy), data.expected)
    }

    function test_autopilot_data() {
        return [
            { tag: "ready",             snapshot: { readyAvailable: true, ready: true },    expected: Rules.ok },
            { tag: "not ready",         snapshot: { readyAvailable: true, ready: false },   expected: Rules.warning },
            { tag: "not supported",     snapshot: { readyAvailable: false, ready: true },   expected: Rules.unknown }
        ]
    }

    function test_autopilot(data) {
        compare(levelOf("autopilot", data.snapshot), data.expected)
    }

    function test_evaluateDoesNotMutateInputs() {
        var snapshot = Fixtures.healthySnapshot()
        var policy = Fixtures.defaultPolicy()
        var snapshotBefore = JSON.stringify(snapshot)
        var policyBefore = JSON.stringify(policy)
        Rules.evaluate(snapshot, policy)
        compare(JSON.stringify(snapshot), snapshotBefore)
        compare(JSON.stringify(policy), policyBefore)
    }

    function test_summarize() {
        var rows = [
            Rules.row("a", "A", Rules.ok, ""),
            Rules.row("b", "B", Rules.ok, ""),
            Rules.row("c", "C", Rules.warning, ""),
            Rules.row("d", "D", Rules.unknown, ""),
            Rules.row("e", "E", Rules.info, ""),
            Rules.row("f", "F", "bogus", "")
        ]
        compare(Rules.summarize(rows), { ok: 2, warning: 1, unknown: 1, info: 1 })
        compare(Rules.summarize([]), { ok: 0, warning: 0, unknown: 0, info: 0 })
    }

    function test_attentionRowsPreserveOrder() {
        var rows = [
            Rules.row("a", "A", Rules.unknown, ""),
            Rules.row("b", "B", Rules.ok, ""),
            Rules.row("c", "C", Rules.warning, ""),
            Rules.row("d", "D", Rules.info, ""),
            Rules.row("e", "E", Rules.unknown, "")
        ]
        compare(Rules.attentionRows(rows).map(function(row) { return row.key }), ["a", "c", "e"])
        compare(rows.length, 5)
    }
}
