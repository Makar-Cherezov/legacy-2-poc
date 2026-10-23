#include "FlyViewSettingsTest.h"

#include <QtCore/QSettings>

#include "Fact.h"
#include "FactMetaData.h"
#include "FlyViewSettings.h"
#include "SettingsManager.h"

UT_REGISTER_TEST(FlyViewSettingsTest, TestLabel::Unit)

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

QList<Fact *> visibilityToggles(FlyViewSettings *settings)
{
    return {settings->showMapScale(), settings->showCameraControls(), settings->showTelemetryPanel()};
}

}  // namespace

void FlyViewSettingsTest::_visibilityTogglesDefaultTest()
{
    FlyViewSettings *settings = SettingsManager::instance()->flyViewSettings();
    QVERIFY(settings);

    for (Fact *fact : visibilityToggles(settings)) {
        QCOMPARE(fact->type(), FactMetaData::valueTypeBool);
        QCOMPARE(fact->rawDefaultValue().toBool(), true);
        QCOMPARE(fact->rawValue().toBool(), true);
    }
}

void FlyViewSettingsTest::_visibilityTogglesPersistenceTest()
{
    FlyViewSettings *settings = SettingsManager::instance()->flyViewSettings();
    QVERIFY(settings);

    for (Fact *fact : visibilityToggles(settings)) {
        SettingRestorer restorer(fact);

        fact->setRawValue(false);

        QSettings stored;
        stored.beginGroup(FlyViewSettings::settingsGroup);
        QCOMPARE(stored.value(fact->name()).toBool(), false);
    }
}
