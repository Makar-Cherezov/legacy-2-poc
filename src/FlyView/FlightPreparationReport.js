.pragma library
.import "FlightPreparationRules.js" as Rules

/// Formats a captured review as plain text without changing or saving state.
function create(snapshot, rows, checks, checked, note, capturedAt) {
    var lines = [
        qsTranslate("FlightPreparationReport", "Flight preparation report"),
        qsTranslate("FlightPreparationReport", "Captured: %1").arg(capturedAt),
        snapshot.connected ? qsTranslate("FlightPreparationReport", "Vehicle: %1").arg(snapshot.vehicleId)
                           : qsTranslate("FlightPreparationReport", "No vehicle connected"),
        qsTranslate("FlightPreparationReport", "Flight mode: %1").arg(snapshot.flightMode || qsTranslate("FlightPreparationReport", "Unknown")),
        qsTranslate("FlightPreparationReport", "This is a review snapshot, not an authorization to fly."),
        "",
        qsTranslate("FlightPreparationReport", "Automatic checks")
    ]
    for (var i = 0; i < rows.length; ++i) {
        lines.push("[" + Rules.label(rows[i].level) + "] " + rows[i].title + ": " + rows[i].detail)
    }
    lines.push("", qsTranslate("FlightPreparationReport", "Site checks"))
    for (var j = 0; j < checks.length; ++j) {
        var state = checked[checks[j].key] === true ? qsTranslate("FlightPreparationReport", "Reviewed")
                                                   : qsTranslate("FlightPreparationReport", "Not reviewed")
        lines.push("[" + state + "] " + checks[j].title)
    }
    if (note.trim().length) {
        lines.push("", qsTranslate("FlightPreparationReport", "Operator note"), note.trim())
    }
    return lines.join("\n")
}
