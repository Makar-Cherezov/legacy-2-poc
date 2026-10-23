# Расхождения описания команды с реальным кодом

Проверено по исходникам форка `qgc_fake` и V5.1 (статически, без сборки).

| # | Утверждение команды | Реальность | Статус |
|---|---|---|---|
| 1 | Шаг 5.1.4: условие `showMapScale` добавить в PiP-масштаб (`FlyViewMap.qml`) | В самом форке PiP-масштаб настройкой НЕ управлялся (только в `FlyViewWidgetLayer`). Мы добавили условие и в PiP — это расширение поведения форка | учтено |
| 2 | `showCameraControls` в `FlyViewTopRightColumnLayout` и `FlyViewTopRightPanel` | В форке условие стояло одно (`PhotoVideoControl.qml`); в V5.1 два Loader'а — оба обработаны | учтено |
| 3 | Тесты/код используют `settings.visible` | В V5.1 свойство называется `userVisible` | исправлено |
| 4 | `vehicle.autopilot`, `rcRSSI` число, `missionItemCount`, `missionDistance` | Подтверждено, что в V5.1 они изменились (см. PROGRESS.md) | исправлено |
| 5 | `showMultiVehicleSelector` заменён `enableMultiVehiclePanel` | В форке `showMultiVehicleSelector` реально используется; замена в V5.1 логична, но поведение (две настройки vs одна) — не идентично | не переносили |
| 6 | Замечание 1 (обрезка заметки рвёт привязку) | Подтверждено в коде форка | исправлено, нужна проверка UI-07 |
| 7 | Замечание 2 (255 спутников → «0 satellites») | Не проверено на V5.1 | открыто |
| 8 | Тесты лежат в `src/Vehicle/...`, `test/qml/...` (раздел 3 документа) | В репозитории команды они в `tests/Settings`, `tests/Vehicle`, `tests/qml/FlightPreparation` — пути в документе устарели | инфо |
| 9 | В `FlightPreparationSettingsTest` команды смешаны проверки Flight Preparation и Fly View | В V5.1 разнесены на два теста; `showMultiVehicleSelector` из теста убран | сделано |

Дополняйте таблицу по мере проверки (особенно по результатам сборки и ручных тестов).
