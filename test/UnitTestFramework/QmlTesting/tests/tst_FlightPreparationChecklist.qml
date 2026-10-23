import QtQuick
import QtTest

import "../../../../src/FlyView/FlightPreparationChecklist.js" as Checklist

TestCase {
    name: "FlightPreparationChecklist"

    function test_itemsHaveStableUniqueKeys() {
        var items = Checklist.items()
        compare(items.map(function(item) { return item.key }),
                ["airframe", "battery", "payload", "area", "weather", "control", "return"])
        for (var i = 0; i < items.length; ++i) {
            verify(items[i].title.length > 0, items[i].key)
            verify(items[i].detail.length > 0, items[i].key)
        }
    }

    function test_itemsReturnFreshCopies() {
        var first = Checklist.items()
        first[0].key = "changed"
        compare(Checklist.items()[0].key, "airframe")
    }

    function test_completed_data() {
        return [
            { tag: "none",              checked: {},                                            expected: 0 },
            { tag: "one",               checked: { airframe: true },                            expected: 1 },
            { tag: "unchecked ignored", checked: { airframe: true, battery: false },            expected: 1 },
            { tag: "truthy ignored",    checked: { airframe: 1, battery: "yes" },               expected: 0 },
            { tag: "unknown ignored",   checked: { airframe: true, stale: true, other: true },  expected: 1 }
        ]
    }

    function test_completed(data) {
        compare(Checklist.completed(Checklist.items(), data.checked), data.expected)
    }

    function test_completedAll() {
        var items = Checklist.items()
        var checked = {}
        for (var i = 0; i < items.length; ++i) {
            checked[items[i].key] = true
        }
        compare(Checklist.completed(items, checked), items.length)
    }
}
