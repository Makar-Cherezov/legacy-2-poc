import QtQuick
import QtTest

import "../../../../src/FlyView/FlightPreparationReport.js" as Report
import "../../../../src/FlyView/FlightPreparationRules.js" as Rules
import "FlightPreparationFixtures.js" as Fixtures

TestCase {
    name: "FlightPreparationReport"

    readonly property var checks: [
        { key: "airframe", title: "Airframe and propulsion" },
        { key: "area", title: "Launch and recovery area" }
    ]
    readonly property var rows: [
        Rules.row("connection", "Connection", Rules.ok, "1.5% cumulative packet loss."),
        Rules.row("gps", "GPS", Rules.warning, "Waiting for a 3D GPS fix.")
    ]

    function lines(report) {
        return report.split("\n")
    }

    function test_connectedReport() {
        var report = Report.create(Fixtures.healthySnapshot({ vehicleId: 7, flightMode: "Hold" }),
                                   rows, checks, { airframe: true }, "", "2026-10-17T10:00:00.000Z")
        compare(lines(report), [
            "Flight preparation report",
            "Captured: 2026-10-17T10:00:00.000Z",
            "Vehicle: 7",
            "Flight mode: Hold",
            "This is a review snapshot, not an authorization to fly.",
            "",
            "Automatic checks",
            "[OK] Connection: 1.5% cumulative packet loss.",
            "[Attention] GPS: Waiting for a 3D GPS fix.",
            "",
            "Site checks",
            "[Reviewed] Airframe and propulsion",
            "[Not reviewed] Launch and recovery area"
        ])
    }

    function test_disconnectedReport() {
        var report = lines(Report.create(Fixtures.healthySnapshot({ connected: false, flightMode: "" }),
                                         [], checks, {}, "", "t"))
        compare(report[2], "No vehicle connected")
        compare(report[3], "Flight mode: Unknown")
    }

    function test_noteIsTrimmedAndAppended() {
        var report = lines(Report.create(Fixtures.healthySnapshot(), rows, checks, {}, "  Wind 5 m/s  \n", "t"))
        compare(report.slice(-3), ["", "Operator note", "Wind 5 m/s"])
    }

    function test_blankNoteIsOmitted() {
        var report = Report.create(Fixtures.healthySnapshot(), rows, checks, {}, "   \n\t", "t")
        verify(report.indexOf("Operator note") === -1)
        compare(lines(report).slice(-1)[0], "[Not reviewed] Launch and recovery area")
    }

    function test_onlyExplicitTrueIsReviewed() {
        var report = Report.create(Fixtures.healthySnapshot(), [], checks, { airframe: "true", area: 1 }, "", "t")
        verify(report.indexOf("[Reviewed]") === -1)
    }

    function test_createDoesNotMutateInputs() {
        var snapshot = Fixtures.healthySnapshot()
        var checked = { airframe: true }
        var snapshotBefore = JSON.stringify(snapshot)
        Report.create(snapshot, rows, checks, checked, "note", "t")
        compare(JSON.stringify(snapshot), snapshotBefore)
        compare(checked, { airframe: true })
        compare(rows.length, 2)
    }
}
