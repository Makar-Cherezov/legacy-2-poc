# Проделанная работа

Статус: **[написано]** = код есть, не компилировался; **[проверено]** = подтверждено сборкой/тестами
(отмечайте здесь, когда проверите).

## B. Настройки видимости Fly View — [написано]
- `src/Settings/FlyView.SettingsGroup.json` — +`showMapScale`, `showCameraControls`, `showTelemetryPanel` (bool, default true, с `label`/`keywords`)
- `src/Settings/FlyViewSettings.{h,cc}` — +3 `DEFINE_SETTINGFACT` / `DECLARE_SETTINGSFACT`
- `src/AppSettings/pages/FlyView.SettingsUI.json` — 3 пункта в группе «General» + keywords
- Условия видимости:
  - `src/FlyView/FlyViewWidgetLayer.qml` — оба `MapScale` (2D и Viewer3D scale bar)
  - `src/FlyView/FlyViewMap.qml` — масштаб в PiP
  - `src/FlyView/FlyViewBottomRightRowLayout.qml` — `TelemetryValuesBar.visible`
  - `src/FlyView/FlyViewTopRightColumnLayout.qml`, `FlyViewTopRightPanel.qml` — Loader `PhotoVideoControl`
- Тест: `test/Settings/FlyViewSettingsTest.{h,cc}` (SET-07, SET-08), зарегистрирован в `test/Settings/CMakeLists.txt`

## A. Flight Preparation — [написано]
- Настройки: `src/Settings/FlightPreparationSettings.{h,cc}`, `FlightPreparation.SettingsGroup.json`
  (JSON подхватывается glob'ом `qgc_add_json_resources`), `src/Settings/CMakeLists.txt`,
  `SettingsManager.{h,cc}` (`flightPreparationSettings`, `Q_MOC_INCLUDE`)
- Логика (`src/FlyView/`): `FlightPreparationSnapshot.js`, `Rules.js`, `Checklist.js`, `Report.js` (`.pragma library`)
- Модель: `FlightPreparationModel.qml`
- UI: 19 файлов `FlightPreparation*.qml` (Popup, Summary, Overview, SiteChecks, Mission, Position, Notes,
  SettingsView, Threshold, ResetDialog, StatusCard, Badge, Metric, Section, ConnectionDetails,
  BatteryDetails, ManualCheck, ShowAction)
- Все 23 файла добавлены в `QML_FILES` в `src/FlyView/CMakeLists.txt` (включая `.js` — ПРОВЕРИТЬ, что qt_add_qml_module это принимает)
- Интеграция: `FlyViewToolStripActionList.qml` (+сигнал и `FlightPreparationShowAction`), `FlyViewToolStrip.qml`
  (проброс сигнала), `FlyViewWidgetLayer.qml` (модель, `Component` popup, `onDisplayFlightPreparation`),
  `custom-example/src/FlyViewToolStripActionList.qml` (то же для кастомной сборки),
  пункт `flightPreparationSettings.showPreparation` в `FlyView.SettingsUI.json`
- Адаптации под V5.1 (в `FlightPreparationSnapshot.js`):
  - `vehicle.autopilot.setupComplete` → `vehicle.autopilotPlugin.setupComplete`
  - `vehicle.rcRSSI` — теперь Fact → `factValue(vehicle.rcRSSI)` (sentinel 255 = «нет данных» не нормализуется; в правилах `rcRssi` не используется)
  - `mission.missionItemCount` (удалён) → `Snapshot.missionItemCount(mission)` = `visualItems.count - 1` (минус элемент MissionSettings)
  - `mission.missionDistance` → `mission.missionTotalDistance`
- Адаптации под Qt 6: импорты без версий, убраны `QGroundControl.ScreenTools/Palette`,
  `StandardButton.*` → `Dialog.*`
- Исправлено замечание 1 из документа команды: `FlightPreparationNotes.qml` использует `remove(4000, length)` вместо `text = text.slice(...)`
  (привязка `text: preparation.note` не рвётся). Требует ручной проверки UI-07.
- `FlightPreparationShowAction.qml`: `.visible` → `.userVisible` (в V5.1 свойство группы настроек называется `userVisible`).

## Тесты — [написано]
- C++: `test/Settings/FlightPreparationSettingsTest.{h,cc}` (SET-01..06), `FlyViewSettingsTest.{h,cc}` (SET-07/08)
- QML (`test/UnitTestFramework/QmlTesting/tests/`): `tst_FlightPreparation{Rules,Checklist,Report,Snapshot,Model}.qml`
  + `FlightPreparationFixtures.js`. Пути к `.js` — `../../../../src/FlyView/`. Фикстуры обновлены под
  `autopilotPlugin`, `rcRSSI` как Fact, `visualItems.count`, `missionTotalDistance`;
  добавлены `test_missionItemCount`, `test_rcRssiIsFact`.
- Тесты команды перенесены из `tests/` репозитория команды; логика правил/отчёта/чек-листа не менялась.

## Не делалось (осознанно)
- C (GPS): уже есть в V5.1, тесты GPS-01..10 для V5.1 не портировались (можно добавить в `test/Vehicle/` при желании).
- D (меню): по желанию продукта.
- E, F: неприменимо.
- Переводы: через Crowdin.
