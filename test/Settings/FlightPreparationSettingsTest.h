#pragma once

#include "UnitTest.h"

/// Covers the flight preparation review policy settings (SET-01..06)
class FlightPreparationSettingsTest : public UnitTest
{
    Q_OBJECT

private slots:
    void _groupNameTest();
    void _defaultValuesTest();
    void _metaDataTest();
    void _rangeValidationTest_data();
    void _rangeValidationTest();
    void _settingsPersistenceTest();
    void _settingsManagerExposureTest();
};
