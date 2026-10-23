# Дальнейшие шаги

## 1. Сборка (на машине коллеги)
```bash
git clone <URL этого репозитория> && cd <repo>
python3 tools/configure.py -B build -t Debug --testing --qt-root <путь к Qt 6.11.1, напр. ~/Qt/6.11.1/macos>
cmake --build build --parallel
```
или `just configure && just build` (нужен `QT_DIR`). Все ошибки компиляции/конфигурации записывать в `HANDOFF_LOG.md`
и исправлять; вероятные места — см. раздел 5.

## 2. Быстрый прогон QML-логики (без сборки QGC)
```bash
QT_QPA_PLATFORM=offscreen qmltestrunner -input test/UnitTestFramework/QmlTesting/tests
```
Должны пройти 5 файлов `tst_FlightPreparation*.qml`. Если `qmltestrunner` не находит `QtQuick` —
проверить `QML_IMPORT_PATH`/PATH на Qt 6.

## 3. Тесты в сборке
```bash
cd build
ctest -R "FlightPreparationSettingsTest|FlyViewSettingsTest" --output-on-failure
ctest -R QmlQuickTests --output-on-failure
ctest --output-on-failure -L Unit      # регрессия
```
Линт: `just lint` (qmllint + qmlformat). Исправить предупреждения в новых файлах `FlightPreparation*.qml`.

## 4. Ручная проверка UI (сценарии UI-01..UI-10 из reference/TEAM_FORK_CHANGES_ANALYSIS.md)
Запустить QGC + SITL: UI-01 (без аппарата — кнопка «Preparation», popup, Summary «No vehicle connected»),
UI-02 (`showPreparation`=off скрывает кнопку), UI-03/04 (строки и пороги), UI-05 (сброс отметок при дизарме/потере связи),
UI-06 (отчёт стабилен), **UI-07 (заметка >4000 символов → «Start a new review» очищает редактор — проверка исправления)**,
UI-08 (три флажка Fly View скрывают/показывают масштаб, камеру, панель телеметрии; переживают перезапуск; проверить и PiP),
UI-09 пропустить (D не делали), UI-10 (русская локаль — зависит от Crowdin).
Отдельно проверить пересечения: `enableMultiVehiclePanel`, режим Viewer3D, кастомная сборка (`custom-example`).

## 5. Вероятные проблемы (проверить в первую очередь)
1. `.js` в `QML_FILES` модуля `FlyViewModule` — если CMake/qmlcachegen ругается, перенести JS в `qt_add_resources` или
   `set_source_files_properties(... QT_RESOURCE_ALIAS)`; убедиться, что `import "X.js" as Y` резолвится.
2. `QGCPalette`, `ScreenTools`, `FactTextField`, `FactCheckBox` в `import QGroundControl`/`.Controls`/`.FactControls` — проверить qmllint.
3. `qsTranslate()` внутри `.pragma library` — убедиться, что работает в Qt 6 (иначе заменить на `QT_TR_NOOP`/передачу переводов).
4. Имена в C++-тестах: `Fact::rawUnits/rawMin/rawMax/decimalPlaces/defaultValueAvailable`, `SettingsGroup::userVisible()`,
   `SettingsManager::instance()` — по месту подогнать под реальный API.
5. `QGC::runningUnitTests()` в V5.1: `SettingsFact` не читает сохранённые значения — тесты персистентности пишут и читают `QSettings` напрямую; проверить, что значение действительно пишется.
6. Директорный импорт `import "../../../../src/FlyView"` в `tst_FlightPreparationModel.qml` — если QML-раннер не разрешает, импортировать `FlightPreparationModel.qml` по относительному пути.
7. Вычисление `missionItems` (`visualItems.count - 1`) — сверить с реальным `MissionController` (в `visualItems` первым идёт MissionSettingsItem).
8. Замечание 2 из документа команды («0 спутников → Attention, а не Unknown» при `satellites_visible==255`):
   проверить, как V5.1 `VehicleGPSFactGroup` нормализует 255; решить, нужно ли менять `Rules.js`.

## 6. Затем
- Оформить итоговую сводку: что в описании команды верно / неверно (раздел 4 и 5 документа) — наполнять `DISCREPANCIES.md`.
- По желанию: D (порядок меню), тесты GPS-01..10 для V5.1 (`test/Vehicle/`), `custom-example` — проверить сборку с `-DQGC_CUSTOM_BUILD`.
- Коммиты в стиле проекта (conventional commits): `feat(Settings): ...`, `feat(FlyView): ...`, `test(...)`.
