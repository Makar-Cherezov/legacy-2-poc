#pragma once

#include <QtQmlIntegration/QtQmlIntegration>

#include "SettingsGroup.h"

/// Operator thresholds for the read-only flight preparation briefing.
/// These settings affect local presentation, never vehicle parameters.
class FlightPreparationSettings : public SettingsGroup
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    /// Loads persistent briefing preferences and their Fact metadata.
    explicit FlightPreparationSettings(QObject* parent = nullptr);

    DEFINE_SETTING_NAME_GROUP()

    DEFINE_SETTINGFACT(showPreparation)
    DEFINE_SETTINGFACT(minimumBatteryPercent)
    DEFINE_SETTINGFACT(minimumSatellites)
    DEFINE_SETTINGFACT(maximumHdop)
    DEFINE_SETTINGFACT(maximumPacketLoss)
    DEFINE_SETTINGFACT(requireGps)
    DEFINE_SETTINGFACT(requireHome)
    DEFINE_SETTINGFACT(requireMission)
    DEFINE_SETTINGFACT(requireRc)
};
