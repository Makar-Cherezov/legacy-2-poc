#pragma once

#include "UnitTest.h"

/// Covers the Fly View visibility toggles (SET-07, SET-08)
class FlyViewSettingsTest : public UnitTest
{
    Q_OBJECT

private slots:
    void _visibilityTogglesDefaultTest();
    void _visibilityTogglesPersistenceTest();
};
