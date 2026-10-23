#include "FlightPreparationSettingsTest.h"

#include <QtCore/QSettings>

#include "Fact.h"
#include "FactMetaData.h"
#include "FlightPreparationSettings.h"
#include "SettingsManager.h"

UT_REGISTER_TEST(FlightPreparationSettingsTest, TestLabel::Unit)

namespace {

/// Restores the stored value even when a QCOMPARE returns early.
class SettingRestorer
{
public:
    explicit SettingRestorer(Fact *fact) : _fact(fact), _originalValue(fact->rawValue()) {}
    ~SettingRestorer() { _fact->setRawValue(_originalValue); }

private:
    Fact *_fact;
    QVariant _originalValue;
};

QVariant storedValue(const char *group, const QString &name)
{
    QSettings settings;
    settings.beginGroup(group);
    return settings.value(name);
}

}  // namespace

void FlightPreparationSettingsTest::_groupNameTest()
{
    QCOMPARE(QString(FlightPreparationSettings::name), QStringLiteral("FlightPreparation"));
    QCOMPARE(QString(FlightPreparationSettings::settingsGroup), QStringLiteral("FlightPreparation"));
}

void FlightPreparationSettingsTest::_defaultValuesTest()
{
    FlightPreparationSettings settings;

    QCOMPARE(settings.showPreparation()->rawValue().toBool(), true);
    QCOMPARE(settings.minimumBatteryPercent()->rawValue().toUInt(), 40u);
    QCOMPARE(settings.minimumSatellites()->rawValue().toUInt(), 8u);
    QCOMPARE(settings.maximumHdop()->rawValue().toDouble(), 2.0);
    QCOMPARE(settings.maximumPacketLoss()->rawValue().toDouble(), 10.0);
    QCOMPARE(settings.requireGps()->rawValue().toBool(), true);
    QCOMPARE(settings.requireHome()->rawValue().toBool(), true);
    QCOMPARE(settings.requireMission()->rawValue().toBool(), false);
    QCOMPARE(settings.requireRc()->rawValue().toBool(), false);
}

void FlightPreparationSettingsTest::_metaDataTest()
{
    FlightPreparationSettings settings;

    QCOMPARE(settings.minimumBatteryPercent()->type(), FactMetaData::valueTypeUint32);
    QCOMPARE(settings.minimumBatteryPercent()->rawUnits(), QStringLiteral("%"));
    QCOMPARE(settings.minimumBatteryPercent()->rawMin().toUInt(), 1u);
    QCOMPARE(settings.minimumBatteryPercent()->rawMax().toUInt(), 100u);

    QCOMPARE(settings.minimumSatellites()->type(), FactMetaData::valueTypeUint32);
    QCOMPARE(settings.minimumSatellites()->rawMin().toUInt(), 4u);
    QCOMPARE(settings.minimumSatellites()->rawMax().toUInt(), 99u);

    QCOMPARE(settings.maximumHdop()->type(), FactMetaData::valueTypeDouble);
    QCOMPARE(settings.maximumHdop()->rawMin().toDouble(), 0.5);
    QCOMPARE(settings.maximumHdop()->rawMax().toDouble(), 20.0);
    QCOMPARE(settings.maximumHdop()->decimalPlaces(), 1);

    QCOMPARE(settings.maximumPacketLoss()->type(), FactMetaData::valueTypeDouble);
    QCOMPARE(settings.maximumPacketLoss()->rawUnits(), QStringLiteral("%"));
    QCOMPARE(settings.maximumPacketLoss()->rawMin().toDouble(), 0.0);
    QCOMPARE(settings.maximumPacketLoss()->rawMax().toDouble(), 100.0);

    for (Fact *fact : {settings.showPreparation(), settings.requireGps(), settings.requireHome(),
                       settings.requireMission(), settings.requireRc()}) {
        QCOMPARE(fact->type(), FactMetaData::valueTypeBool);
        QVERIFY(fact->defaultValueAvailable());
    }
}

void FlightPreparationSettingsTest::_rangeValidationTest_data()
{
    QTest::addColumn<QString>("factName");
    QTest::addColumn<QString>("value");
    QTest::addColumn<bool>("valid");

    QTest::newRow("battery below minimum") << "minimumBatteryPercent" << "0" << false;
    QTest::newRow("battery minimum") << "minimumBatteryPercent" << "1" << true;
    QTest::newRow("battery maximum") << "minimumBatteryPercent" << "100" << true;
    QTest::newRow("battery above maximum") << "minimumBatteryPercent" << "101" << false;
    QTest::newRow("satellites below minimum") << "minimumSatellites" << "3" << false;
    QTest::newRow("satellites minimum") << "minimumSatellites" << "4" << true;
    QTest::newRow("satellites above maximum") << "minimumSatellites" << "100" << false;
    QTest::newRow("hdop below minimum") << "maximumHdop" << "0.4" << false;
    QTest::newRow("hdop minimum") << "maximumHdop" << "0.5" << true;
    QTest::newRow("hdop above maximum") << "maximumHdop" << "20.1" << false;
    QTest::newRow("packet loss minimum") << "maximumPacketLoss" << "0" << true;
    QTest::newRow("packet loss maximum") << "maximumPacketLoss" << "100" << true;
    QTest::newRow("packet loss above maximum") << "maximumPacketLoss" << "100.1" << false;
    QTest::newRow("packet loss not a number") << "maximumPacketLoss" << "abc" << false;
}

void FlightPreparationSettingsTest::_rangeValidationTest()
{
    QFETCH(QString, factName);
    QFETCH(QString, value);
    QFETCH(bool, valid);

    FlightPreparationSettings settings;
    Fact *fact = settings.property(factName.toLatin1().constData()).value<Fact *>();
    QVERIFY(fact);

    QCOMPARE(fact->validate(value, false /* convertOnly */).isEmpty(), valid);
}

void FlightPreparationSettingsTest::_settingsPersistenceTest()
{
    FlightPreparationSettings settings;
    Fact *fact = settings.minimumBatteryPercent();
    SettingRestorer restorer(fact);

    fact->setRawValue(55u);

    QCOMPARE(storedValue(FlightPreparationSettings::settingsGroup, fact->name()).toUInt(), 55u);
}

void FlightPreparationSettingsTest::_settingsManagerExposureTest()
{
    SettingsManager *settingsManager = SettingsManager::instance();
    QVERIFY(settingsManager);

    FlightPreparationSettings *settings = settingsManager->flightPreparationSettings();
    QVERIFY(settings);
    QVERIFY(settings->userVisible());
    QCOMPARE(settingsManager->property("flightPreparationSettings").value<QObject *>(), static_cast<QObject *>(settings));
}
