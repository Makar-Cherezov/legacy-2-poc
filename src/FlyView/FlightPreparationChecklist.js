.pragma library

/// Returns session-only operator checks with stable keys for state and reports.
function items() {
    return [
        { key: "airframe", title: qsTranslate("FlightPreparationChecklist", "Airframe and propulsion"),
          detail: qsTranslate("FlightPreparationChecklist", "Inspect the structure, propellers and fasteners. Remove transport restraints.") },
        { key: "battery", title: qsTranslate("FlightPreparationChecklist", "Power installation"),
          detail: qsTranslate("FlightPreparationChecklist", "Secure every battery and connector. Check for damage, swelling and adequate charge.") },
        { key: "payload", title: qsTranslate("FlightPreparationChecklist", "Payload and recording"),
          detail: qsTranslate("FlightPreparationChecklist", "Secure the payload, remove covers and check storage and recording settings.") },
        { key: "area", title: qsTranslate("FlightPreparationChecklist", "Launch and recovery area"),
          detail: qsTranslate("FlightPreparationChecklist", "Check clearance, people, obstacles and a suitable recovery location.") },
        { key: "weather", title: qsTranslate("FlightPreparationChecklist", "Weather and operating limits"),
          detail: qsTranslate("FlightPreparationChecklist", "Check wind, visibility and local conditions against the aircraft's operating limits.") },
        { key: "control", title: qsTranslate("FlightPreparationChecklist", "Control and communication"),
          detail: qsTranslate("FlightPreparationChecklist", "Verify control response, range and the agreed lost-link procedure.") },
        { key: "return", title: qsTranslate("FlightPreparationChecklist", "Return and contingency plan"),
          detail: qsTranslate("FlightPreparationChecklist", "Verify home location, return height, battery reserve and the emergency landing plan.") }
    ]
}

/// Counts only known checks, ignoring stale or unrelated keys.
function completed(items, checked) {
    var count = 0
    for (var i = 0; i < items.length; ++i) {
        if (checked[items[i].key] === true) {
            ++count
        }
    }
    return count
}
