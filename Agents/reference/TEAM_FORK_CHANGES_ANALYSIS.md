# Анализ форка qgc_fake относительно qgroundcontrol@495a17b4

## 0. Исходные данные и метод

- Базовый коммит: `495a17b4964d3ed90f241388b3a02a35e96c9663` (2024-12-02, «CI: remove yet another Android platform we don't want»). Коммит лежит на ветке `Stable_V4.4`, `git describe` = `v4.4.3`. Это последняя стабильная версия на Qt 5 и qmake.
- В форке `qgc_fake` нет каталога `.git`. Поэтому дерево форка сравнивалось с `git archive 495a17b4` командой `diff -rq --strip-trailing-cr`.
- Что исключено из сравнения:
  - концы строк (CRLF и LF);
  - содержимое субмодулей: `libs/*`, `src/GPS/Drivers`, `src/FirmwarePlugin/APM/ArduPilot-Parameter-Repository`. `git archive` не выгружает субмодули, поэтому в форке они выглядят как новые файлы. Их ревизии не сверялись, так как в форке нет `.git`;
  - симлинки `libs/Frameworks/SDL2.framework/Versions/Current`: они не распаковываются на Windows.
- Целевая ветка для переноса: `origin/Stable_V5.1` @ `07a764127` (2026-10-15). Это Qt 6, только CMake, переработанный Fly View и новый docker-конвейер.

## 1. Список изменений форка

### A. Новая функция «Flight Preparation» (подготовка к полёту)

В Fly View добавлен только читающий инструмент. Он сводит телеметрию в проверки со статусами `ok / warning / unknown / info` и ведёт сессионный чек-лист площадки. Ещё он хранит заметку оператора и формирует текстовый отчёт. Пороги проверок вынесены в отдельную группу настроек. Инструмент не меняет ни аппарат, ни параметры, ни миссию.

| Слой | Файлы |
|---|---|
| Логика (JS, `.pragma library`) | `src/FlightDisplay/FlightPreparationSnapshot.js` — нормализует данные Vehicle и MissionController в снимок; `FlightPreparationRules.js` — 10 групп правил (connection, parameters, setup, battery-N, gps, home, sensors, rc, mission, autopilot), а также `summarize` и `attentionRows`; `FlightPreparationChecklist.js` — 7 ручных проверок; `FlightPreparationReport.js` — текстовый отчёт |
| Модель сессии | `FlightPreparationModel.qml`: правила, политика из настроек, `checkedItems`, `note`, `report`. Сессия сбрасывается при смене аппарата, потере live-связи и дизарме |
| UI | `FlightPreparationPopup`, `Summary`, `Overview`, `SiteChecks`, `Mission`, `Position`, `Notes`, `SettingsView`, `Threshold`, `ResetDialog`, `StatusCard`, `Badge`, `Metric`, `Section`, `ConnectionDetails`, `BatteryDetails`, `ManualCheck`, `ShowAction` (все файлы `.qml`) |
| Настройки (C++) | `src/Settings/FlightPreparationSettings.{h,cc}`, `FlightPreparation.SettingsGroup.json`: `showPreparation`, `minimumBatteryPercent` (40, 1..100 %), `minimumSatellites` (8, 4..99), `maximumHdop` (2, 0.5..20), `maximumPacketLoss` (10, 0..100 %), `requireGps` (true), `requireHome` (true), `requireMission` (false), `requireRc` (false) |
| Интеграция | `SettingsManager.{h,cc}` (свойство `flightPreparationSettings`), `FlyViewToolStrip.qml` и `FlyViewToolStripActionList.qml` (действие «Preparation»), `FlyViewWidgetLayer.qml` (экземпляр модели и popup), `GeneralSettings.qml` (флажок «Show Flight Preparation Tool»), `qgroundcontrol.qrc`, `qmldir`, `src/FlightDisplay/CMakeLists.txt`, `src/Settings/CMakeLists.txt`, `qgroundcontrol.pro` |

### B. Настройки видимости элементов Fly View

- В `FlyView.SettingsGroup.json` и `FlyViewSettings.{h,cc}` добавлены четыре bool-настройки, все по умолчанию `true`: `showMapScale`, `showCameraControls`, `showTelemetryPanel`, `showMultiVehicleSelector`.
- Настройки подключены в разметке:
  - `FlyViewWidgetLayer.qml`: масштаб карты, панель телеметрии `TelemetryValuesBar`, переключатель Single/Multi-Vehicle;
  - `PhotoVideoControl.qml`: управление камерой.
- В `GeneralSettings.qml` добавлены четыре флажка.

### C. GPS FactGroup: исправление и рефакторинг

- **Исправление.** `VehicleGPSFactGroup` и `VehicleGPS2FactGroup` теперь вызывают `_setTelemetryAvailable(true)` после `GPS_RAW_INT`, `GPS2_RAW`, `HIGH_LATENCY` и `HIGH_LATENCY2`. В базе флаг `telemetryAvailable` у GPS всегда оставался `false`.
- **Рефакторинг.** Общий `RawGpsData` и `_updateRawGps()` убирают дублирование между GPS1 и GPS2. `_updatePosition()` согласованно обновляет `lat`, `lon` и `mgrs`. Инициализация переведена на `qQNaN()`. Добавлены комментарии о единицах и sentinel-значениях.

### D. Порядок пунктов меню (UX)

- `PlanView/MissionItemEditor.qml`: пункт «Edit position...» перенесён в начало меню.
- `QmlControls/ParameterEditor.qml`: «Save to file...» теперь стоит перед «Load from file...».

### E. Сборка и развёртывание (qmake / Docker)

- Новые файлы: `create_ubuntu_docker.sh`, `build_ubuntu_docker.sh`, `create_android_docker.sh`, `build_android_docker.sh`, `deploy/docker/Dockerfile-build-android`, `.dockerignore`.
- `deploy/docker/Dockerfile-build-linux`: аргументы `UID`/`GID`, пакет `python3-dev`, каталог `~/.ccache`.
- `deploy/docker/install-qt-linux.sh`: пакеты `python3-dev` и `build-essential`, `--no-install-recommends`.
- `QGCCommon.pri`: Android versionCode можно переопределить переменной окружения `QGC_ANDROID_VERSION_CODE_OVERRIDE`. `build_android_docker.sh` передаёт туда `1%y%j%H%M`.
- `src/VideoReceiver/VideoReceiver.pri`: путь к GStreamer для Android можно переопределить через `GSTREAMER_HOME`.
- `.gitignore`: удалена строка `user_config.pri`.
- В дерево положен бинарный артефакт `QGroundControl-v4.4.0.14.AppImage` размером 182 МБ.

### F. Переводы ru_RU

`translations/qgc_ru_RU.ts`, `qgc_source_ru_RU.ts` и `qgc_json_ru_RU.ts` перегенерированы через lupdate. Изменения:
- добавлены контексты FlightPreparation* и строки новых настроек Fly View с русскими переводами;
- дозаполнена часть ранее `unfinished` строк;
- удалены устаревшие контексты (AirMap*, FlightBrief и др.).

### Замечания, найденные при разборе (не исправлялись)

1. `FlightPreparationNotes.qml`: при вводе больше 4000 символов обработчик выполняет `text = text.slice(...)`. Это разрывает привязку `text: preparation.note`. После «Start a new review» модель очищает `note`, а редактор может продолжить показывать старый текст. Проверка — сценарий UI-07.
2. При `satellites_visible == 255` значение `count` нормализуется в 0. В Preparation это даёт «0 satellites → Attention», а не «Unknown». Поведение консервативное, но вводит в заблуждение. Проверка — сценарий R-GPS «zero satellites».
3. AppImage размером 182 МБ лежит в дереве исходников. Это артефакт сборки, переносить его нельзя.

## 2. Тест-план

Обозначения типов: **U** — C++ unit (QtTest, `UnitTest`); **Q** — Qt Quick Test (`tst_*.qml`, чистая логика без C++); **M** — ручная проверка UI; **B** — проверка сборки.

### 2.1 GPS FactGroup (изменение C)

| ID | Тип | Сценарий | Ожидаемый результат |
|---|---|---|---|
| GPS-01 | U | Новый `VehicleGPSFactGroup` | `lat`, `lon`, `hdop`, `vdop` и `cog` равны NaN; `mgrs` = ""; `count` = 0; `telemetryAvailable` = false |
| GPS-02 | U | `GPS_RAW_INT` с полными данными | Масштабирование 1e-7 и /100; `mgrs` равно `convertGeoToMGRS(lat,lon)`; `count` и `lock` заданы; `telemetryAvailable` = true |
| GPS-03 | U | `GPS_RAW_INT` с sentinel-значениями (eph, epv, cog = UINT16_MAX; sats = 255) | hdop, vdop и cog равны NaN; `count` = 0; телеметрия есть |
| GPS-04 | U | Координата (0,0) | lat и lon равны 0, а не NaN; MGRS вычислен |
| GPS-05 | U | Два одинаковых сообщения подряд | `telemetryAvailableChanged` приходит ровно один раз, со значением true |
| GPS-06 | U | `GPS2_RAW` в `VehicleGPS2FactGroup` | Те же значения, что в GPS-02 (паритет GPS1 и GPS2) |
| GPS-07 | U | GPS1 получает `GPS2_RAW`, GPS2 получает `GPS_RAW_INT` | Состояние не меняется; телеметрии нет |
| GPS-08 | U | `HIGH_LATENCY` | lat, lon и mgrs заданы; `count` = 0; hdop не тронут; телеметрия есть |
| GPS-09 | U | `HIGH_LATENCY2` с eph/epv = 15/30 | hdop = 1.5; vdop = 3.0; телеметрия есть |
| GPS-10 | U | `HIGH_LATENCY2` с eph/epv = 255 | hdop и vdop равны NaN |

### 2.2 Настройки (изменения A и B)

| ID | Тип | Сценарий | Ожидаемый результат |
|---|---|---|---|
| SET-01 | U | Имя и QSettings-группа | `FlightPreparation` / `FlightPreparation` |
| SET-02 | U | Значения по умолчанию всех 9 Fact | Совпадают с JSON |
| SET-03 | U | Метаданные: тип, единицы, min/max, decimalPlaces | Совпадают с JSON |
| SET-04 | U | Валидация на границах и за ними (data-driven, 14 строк) | Ошибка только вне диапазона и для нечисловых строк |
| SET-05 | U | Запись Fact | Значение сохраняется в `QSettings` группы `FlightPreparation` |
| SET-06 | U | `SettingsManager` | `flightPreparationSettings()` не null, visible; Q_PROPERTY возвращает тот же объект |
| SET-07 | U | 4 новые настройки FlyView | Тип bool, значение по умолчанию и текущее значение — true |
| SET-08 | U | Запись 4 новых настроек FlyView | Значение сохраняется в `QSettings` группы `FlyView` |

### 2.3 Логика Flight Preparation (изменение A, JS)

| ID | Тип | Сценарий | Ожидаемый результат |
|---|---|---|---|
| R-01 | Q | `inRange`: границы, NaN, ±Infinity, null, undefined, строка | true только для конечного числа в диапазоне |
| R-02 | Q | `label` для всех уровней и неизвестного уровня | Возвращаются OK, Attention, Information, Unknown |
| R-03 | Q | Исправный аппарат | 10 строк в фиксированном порядке; всё `ok`, только RC = `info` |
| R-CONN | Q | Нет связи, связь потеряна, мониторинг выключен, потери NaN или больше 100, потери на пороге и выше | unknown / warning / unknown / unknown / ok / warning |
| R-STALE | Q | Связь не live | Все строки, кроме connection, = unknown (кешированные данные не проходят) |
| R-PARAM | Q | missing, не готово, initialConnect, pendingWrites, приоритет missing | Соответствующие уровни |
| R-SETUP | Q | complete, incomplete, параметры не готовы | ok / warning / unknown |
| R-BAT | Q | Нет телеметрии; chargeState 2..6; chargeState NaN; percent NaN или вне диапазона; ниже порога; на пороге; приоритет неисправности над зарядом | Соответствующие уровни |
| R-BAT-MULTI | Q | Две батареи: исправная и разряженная | Исправная не маскирует разряженную; заголовок по id, если id нет — по индексу |
| R-BAT-POLICY | Q | Изменение `minimumBatteryPercent` | Порог применяется |
| R-GPS | Q | 16 вариантов: требование политикой или аппаратом, fix, sats, hdop, sentinel, RTK | Соответствующие уровни; текст деталей |
| R-HOME / R-SENS / R-RC / R-MIS / R-AP | Q | Все ветви соответствующих правил | Соответствующие уровни |
| R-PURE | Q | `evaluate` | Входной снимок и политика не меняются |
| R-SUM / R-ATT | Q | `summarize` и `attentionRows` | Подсчёт по уровням без мусора; фильтр сохраняет порядок |
| CL-01..04 | Q | Чек-лист | 7 уникальных стабильных ключей; копия на каждый вызов; учитывается только `=== true` и только известные ключи |
| REP-01..06 | Q | Отчёт | Точный формат строк; вариант без аппарата; заметка обрезается по пробелам, пустая заметка опускается; «Reviewed» только для `=== true`; входные данные не меняются |
| SNAP-01..09 | Q | Снимок | `factValue` (NaN для не-числа); null-аппарат; полное отображение полей; маски сенсоров (enabled & present); RC требует presence; невалидные координаты дают NaN, а (0,0) сохраняется; отсутствующие подобъекты; батареи; миссия |
| MOD-01..14 | Q | `FlightPreparationModel` на фейковом реактивном аппарате | Без настроек нет строк; политика и строки реактивны; `setChecked` работает только при live, только для известных ключей и только для `true`; сброс сессии при смене аппарата, потере связи, выключенном мониторинге и дизарме; арм сессию не сбрасывает; отчёт стабилен после изменений телеметрии; модель не меняет аппарат |

### 2.4 UI и интеграция (ручные проверки на сборке форка)

| ID | Тип | Сценарий | Ожидаемый результат |
|---|---|---|---|
| UI-01 | M | Fly View без аппарата | Кнопка «Preparation» есть; popup открывается; Summary = «No vehicle connected»; все строки unknown |
| UI-02 | M | `showPreparation` = false (General settings) | Кнопка скрыта |
| UI-03 | M | SITL PX4/ArduPilot: подключение | Строки становятся ok/warning; вкладки Overview, Site checks, Mission, Notes и Settings работают |
| UI-04 | M | Изменение порога во вкладке Settings | Строка пересчитывается сразу; значение сохраняется после перезапуска |
| UI-05 | M | Отметки site checks → дизарм / отключение link | Отметки сбрасываются |
| UI-06 | M | «Capture review report» | Текст можно выделить; он не меняется при живой телеметрии |
| UI-07 | M | Заметка длиннее 4000 символов → «Start a new review» | Редактор очищен. Это риск из замечания 1 |
| UI-08 | M | 4 флажка видимости Fly View | Масштаб карты, камера, панель телеметрии и мульти-селектор скрываются и показываются; состояние переживает перезапуск |
| UI-09 | M | Меню MissionItemEditor и ParameterEditor | Новый порядок пунктов; действия работают |
| UI-10 | M | Русская локаль | Новые строки переведены |

### 2.5 Сборка и развёртывание (изменение E)

| ID | Тип | Сценарий | Ожидаемый результат |
|---|---|---|---|
| B-01 | B | `create_ubuntu_docker.sh` → `build_ubuntu_docker.sh` | Образ собран с UID/GID хоста; файлы в `build/` принадлежат пользователю; есть AppImage `QGroundControl-<ver>.AppImage` |
| B-02 | B | `create_android_docker.sh` → `build_android_docker.sh` | APK собран; versionCode = override; печатается сертификат apksigner |
| B-03 | B | qmake без `QGC_ANDROID_VERSION_CODE_OVERRIDE` | Прежняя формула `BBMIPPDDD` |
| B-04 | B | `GSTREAMER_HOME` задан / не задан | Используется заданный путь / путь по умолчанию |

## 3. Реализованные тесты

| Файл | Покрывает |
|---|---|
| `src/Vehicle/VehicleGPSFactGroupTest.{h,cc}` | GPS-01..10 |
| `src/Settings/FlightPreparationSettingsTest.{h,cc}` | SET-01..08 |
| `test/qml/FlightPreparation/FlightPreparationFixtures.js` | Общие фикстуры: политика, снимок, батарея |
| `test/qml/FlightPreparation/tst_FlightPreparationRules.qml` | R-* |
| `test/qml/FlightPreparation/tst_FlightPreparationChecklist.qml` | CL-* |
| `test/qml/FlightPreparation/tst_FlightPreparationReport.qml` | REP-* |
| `test/qml/FlightPreparation/tst_FlightPreparationSnapshot.qml` | SNAP-* |
| `test/qml/FlightPreparation/tst_FlightPreparationModel.qml` | MOD-* |

Регистрация C++ тестов: `src/qgcunittest/UnitTestList.cc`, блок unit-тестов в `qgroundcontrol.pro`, `src/CMakeLists.txt` (`add_qgc_test`), `src/Vehicle/CMakeLists.txt` и `src/Settings/CMakeLists.txt` (`EXTRA_SRC` при `BUILD_TESTING`).

Запуск:

```bash
# QML (без сборки QGC): нужен Qt 5.12+ с qmltestrunner и модулем QtTest
QT_QPA_PLATFORM=offscreen qmltestrunner -input test/qml/FlightPreparation

# C++: debug-сборка qmake (unit-тесты включаются в DebugBuild на desktop)
qmake CONFIG+=debug qgroundcontrol.pro && make -j$(nproc)
xvfb-run ./debug/QGroundControl --unittest:VehicleGPSFactGroupTest
xvfb-run ./debug/QGroundControl --unittest:FlightPreparationSettingsTest
```

## 4. Статус изменений относительно Stable_V5.1

| Изменение | Статус в Stable_V5.1 | Обоснование |
|---|---|---|
| C. GPS `telemetryAvailable` | **Уже реализовано** | В `src/Vehicle/FactGroups/VehicleGPSFactGroup.cc` и `VehicleGPS2FactGroup.cc` каждый обработчик вызывает `_setTelemetryAvailable(true)` |
| C. Рефакторинг `RawGpsData` / `_updateRawGps` | Не нужен | В V5.1 обработчики расширены: поле `yaw`, `GNSS_INTEGRITY`, высота в MGRS для high-latency. Перенос рефакторинга без изменения поведения ничего не даёт пользователю, а diff с upstream вырастет |
| B. `showMultiVehicleSelector` | **Уже реализовано** иначе | `AppSettings.enableMultiVehiclePanel` («Enable Multi-Vehicle Panel»): страница FlyView в настройках и `Toolbar/MultiVehicleSelector.qml`, используется в `FlyViewTopRightPanel.qml` |
| B. `showMapScale`, `showCameraControls`, `showTelemetryPanel` | Нет | В V5.1 есть только `corePlugin.options.flyView.showMapScale` (опция сборки, не пользовательская настройка) и `showSimpleCameraControl` (другой смысл). **Перенести** |
| A. Flight Preparation | Нет | **Перенести** с адаптацией к Qt 6 и API V5.1 |
| D. Порядок меню MissionItemEditor | Нет: в V5.1 «Edit position...» по-прежнему последний | Косметика. Перенести по желанию продукта |
| D. Порядок меню ParameterEditor | Нет: в V5.1 пункт «Load from file for review...» стоит перед «Save to file...» | В V5.1 переработан сценарий загрузки (review перед применением). Переставлять пункты по желанию продукта |
| E. `QGCCommon.pri`, `VideoReceiver.pri`, правки `.pro` и `.qrc` | **Неприменимо** | В V5.1 нет qmake: остались только CMake и `qt_add_qml_module` |
| E. `GSTREAMER_HOME` | **Уже реализовано** иначе | CMake-переменная `GStreamer_ROOT_DIR` (`cmake/GStreamer/*`) и автозагрузка |
| E. Android versionCode override | Частично | `cmake/platform/Android.cmake` строит код `BBMIPPDDD`, где DDD — число коммитов после тега. Уникальность ежедневных сборок обеспечена. Явного override нет. Переносить только при реальной потребности (см. 5.4) |
| E. Docker-скрипты и Dockerfile с UID/GID, ccache, python3-dev | **Уже реализовано** иначе | `deploy/docker/Dockerfile`, `run-docker.sh`, `variants.json` (ubuntu, debian, fedora, arch, aarch64, android) и `docker-compose.yml`. UID/GID передаются через `--user` и `QGC_UID`/`QGC_GID` |
| E. `.gitignore` (`user_config.pri`) | Неприменимо | qmake удалён |
| E. AppImage в дереве | Не переносить | Это бинарный артефакт сборки |
| F. Переводы ru_RU | Неприменимо в виде файлов | В V5.1 нет `qgc_ru_RU.ts`. Переводы ведутся через Crowdin (`crowdin.yml`). Переносить только переводы новых строк A и B, через Crowdin, после переноса исходников |

## 5. Шаги переноса на Stable_V5.1

Работать в ветке от `origin/Stable_V5.1`. Перед правками прочитать `CODING_STYLE.md`, `.github/CONTRIBUTING.md` и `test/README.md`. После каждого шага выполнять `just build`, `just lint` и тесты затронутой области.

### 5.1 Настройки видимости Fly View (B, кроме multi-vehicle)

1. Добавить в `src/Settings/FlyView.SettingsGroup.json` три записи: `showMapScale`, `showCameraControls`, `showTelemetryPanel`. Формат V5.1 требует поля `label` и `keywords`, `default: true`.
2. Добавить в `src/Settings/FlyViewSettings.h` три `DEFINE_SETTINGFACT`, а в `FlyViewSettings.cc` — три `DECLARE_SETTINGSFACT`.
3. Вывести настройки в UI: добавить три записи `{"setting": "flyViewSettings.showMapScale"}` и т. д. в группу «General» файла `src/AppSettings/pages/FlyView.SettingsUI.json`. Ключевые слова добавить в `keywords`. `GeneralSettings.qml` в V5.1 для этого не используется.
4. Подключить настройки в разметке V5.1:
   - `src/FlyView/FlyViewWidgetLayer.qml`: оба `MapScale` (2D и 3D) — добавить `&& QGroundControl.settingsManager.flyViewSettings.showMapScale.rawValue`;
   - `src/FlyView/FlyViewMap.qml:779`: масштаб в PiP-окне — то же условие;
   - `src/FlyView/FlyViewBottomRightRowLayout.qml`: `TelemetryValuesBar.visible` = `showTelemetryPanel.rawValue`;
   - `src/FlyView/FlyViewTopRightColumnLayout.qml` (Loader `PhotoVideoControl`) и `FlyViewTopRightPanel.qml:211`: условие `showCameraControls.rawValue`.
5. Не переносить `showMultiVehicleSelector`. Его роль выполняет `appSettings.enableMultiVehiclePanel`.
6. Тест: `test/Settings/FlyViewSettingsTest.{h,cc}` по образцу `AppSettingsTest`, с регистрацией `UT_REGISTER_TEST(FlyViewSettingsTest, TestLabel::Unit)`, `add_qgc_test(FlyViewSettingsTest LABELS Unit)` и источниками в `test/Settings/CMakeLists.txt`. Перенести SET-07 и SET-08. Доступ к настройкам: `SettingsManager::instance()->flyViewSettings()`. Учесть, что в V5.1 `SettingsFact` при `QGC::runningUnitTests()` игнорирует сохранённые значения.
7. Коммит: `feat(FlyView): add user settings to hide map scale, camera controls and telemetry bar`.

### 5.2 Flight Preparation (A)

1. **Настройки (C++).**
   - Создать `src/Settings/FlightPreparationSettings.{h,cc}` в стиле V5.1: `#include <QtQmlIntegration/QtQmlIntegration>`, `QML_ELEMENT`, `QML_UNCREATABLE("")`, пустое тело `DECLARE_SETTINGGROUP` вместо `qmlRegisterUncreatableType`.
   - Перенести `FlightPreparation.SettingsGroup.json`, добавив поля `label` и `keywords`.
   - Добавить файлы в `src/Settings/CMakeLists.txt`. JSON подключается через `qgc_add_json_resources(json_app_settings)`: проверить, что файл попал в список ресурсов.
   - `SettingsManager.h`: forward-declaration, `Q_MOC_INCLUDE("FlightPreparationSettings.h")`, `Q_PROPERTY(QObject *flightPreparationSettings READ flightPreparationSettings CONSTANT)`, геттер и поле `= nullptr`.
   - `SettingsManager.cc`: создание объекта в `init()` рядом с `_flyViewSettings`.
2. **JS-логика.** Перенести 4 файла `.js` в `src/FlyView/`. Синтаксис Qt 6 совместим, но API аппарата нужно адаптировать в `FlightPreparationSnapshot.js`:
   - `vehicle.autopilot.setupComplete` → `vehicle.autopilotPlugin.setupComplete`;
   - `vehicle.rcRSSI` теперь Fact → `factValue(vehicle.rcRSSI)`;
   - `mission.missionItemCount` удалён → вычислять из `missionController.visualItems.count` (с учётом элемента MissionSettings) или убрать метрику;
   - `mission.missionDistance` → `mission.missionTotalDistance`;
   - сверить `vehicle.batteries` (`QmlObjectListModel`: `count`, `get(i)`), `battery.id`, `percentRemaining` и `chargeState` — имена сохранены;
   - сверить `vehicleLinkManager.*`, `parameterManager.*`, `requiresGpsFix`, `readyToFly*` и `sensors*Bits` — имена сохранены.
3. **QML.** Перенести 19 файлов `FlightPreparation*.qml` в `src/FlyView/` и добавить их, вместе с `.js`, в `QML_FILES` модуля `qt_add_qml_module(FlyViewModule ...)` в `src/FlyView/CMakeLists.txt`. Файлы `qmldir` и `.qrc` в V5.1 не используются. Адаптация к Qt 6:
   - импорты без версий: `import QtQuick`, `QtQuick.Controls`, `QtQuick.Layouts`, `QGroundControl`, `QGroundControl.Controls`, `QGroundControl.FactControls`;
   - модули `QGroundControl.ScreenTools` и `QGroundControl.Palette` в V5.1 входят в `QGroundControl` / `QGroundControl.Controls`;
   - `QtQuick.Dialogs 1.3` и `StandardButton.*` → `buttons: Dialog.Close` и `Dialog.Reset | Dialog.Cancel`, как в `FlyViewPreFlightChecklistPopup.qml`;
   - `FlightPreparationNotes.qml`: заменить ручное обрезание `text = text.slice(...)` на ограничение без разрыва привязки (замечание 1). Например, проверять длину в `onTextChanged` и вызывать `remove()`, либо проверять длину в модели;
   - выполнить `just lint`: qmllint и `.qmlformat.ini`.
4. **Интеграция в Fly View.**
   - `FlyViewToolStripActionList.qml`: сигнал `displayFlightPreparation` и `FlightPreparationShowAction { onTriggered: displayFlightPreparation() }`.
   - `FlyViewToolStrip.qml`: проброс сигнала.
   - `FlyViewWidgetLayer.qml`: `FlightPreparationModel { vehicle: _activeVehicle; missionController: _missionController; settings: QGroundControl.settingsManager.flightPreparationSettings }`, `Component { FlightPreparationPopup { preparation: ... } }` и обработчик `onDisplayFlightPreparation` у `toolStrip`.
   - Проверить `custom-example/src/FlyViewToolStripActionList.qml`: переопределённый список действий кастомной сборки. Решить, добавлять ли туда действие.
5. **UI настроек.** Добавить `flightPreparationSettings.showPreparation` в `src/AppSettings/pages/FlyView.SettingsUI.json` (группа «General»). Пороги остаются во вкладке Settings самого popup. По желанию можно сделать отдельную группу «Flight Preparation» на этой странице.
6. **Правила проекта.** Проверить, что QML не разыменовывает `activeVehicle` без проверки на null. Snapshot уже защищён: `connected = !!vehicle`.
7. **Тесты.**
   - C++: `test/Settings/FlightPreparationSettingsTest.{h,cc}` (SET-01..06) с `UT_REGISTER_TEST(..., TestLabel::Unit)` и `add_qgc_test(... LABELS Unit)`.
   - QML: скопировать `tst_FlightPreparation*.qml` и `FlightPreparationFixtures.js` в `test/UnitTestFramework/QmlTesting/tests/`. Импорты без версий (`import QtQuick`, `import QtTest`). Пути к `.js` указать относительно `src/FlyView/`. Вместо импорта каталога в `tst_FlightPreparationModel.qml` использовать модуль `import QGroundControl.FlyView`, если тестовый раннер видит модуль, или относительный путь.
   - Обновить фикстуры аппарата под новые имена: `autopilotPlugin`, `rcRSSI` как Fact, `missionTotalDistance`.
   - Запуск: `ctest -R QmlQuickTests --output-on-failure` и `ctest -R FlightPreparationSettingsTest`.
8. **Переводы.** Новые строки уходят в Crowdin автоматически: `qgc_source_*.ts` и `qgc_json_*.ts` генерируются из исходников. Русские переводы из форка, контексты `FlightPreparation*` в `translations/qgc_source_ru_RU.ts` и `qgc_json_ru_RU.ts` форка, загрузить в Crowdin как предложения. Не коммитить `.ts` вручную.
9. Коммиты: `feat(Settings): add FlightPreparation settings group`, затем `feat(FlyView): add read-only flight preparation briefing`, затем `test(FlyView): cover flight preparation rules and model`.

### 5.3 Порядок меню (D) — по решению продукта

- `src/PlanView/MissionItemEditor.qml`: переместить `QGCMenuItem` «Edit position...» (около строки 250) перед «Move to vehicle position» (около строки 227).
- `src/QmlControls/ParameterEditor.qml`: поменять местами «Load from file for review...» и «Save to file...». Учесть, что в V5.1 изменён сценарий загрузки.
- Коммит: `style(PlanView): ...` или `feat(...)`, если изменение считается UX-изменением.

### 5.4 Сборка (E) — только при реальной потребности

- Переопределение Android versionCode. Добавить в `cmake/platform/Android.cmake` перед вычислением кода:
  `if(DEFINED ENV{QGC_ANDROID_VERSION_CODE_OVERRIDE}) set(ANDROID_VERSION_CODE "$ENV{QGC_ANDROID_VERSION_CODE_OVERRIDE}") ... endif()`.
  Лучше сделать CMake-опцию `QGC_ANDROID_VERSION_CODE_OVERRIDE` и проверять, что значение числовое и не превышает 2100000000. В android-варианте `deploy/docker/variants.json` / `run-docker.sh` пробросить переменную.
- Скрипты `create_*/build_*_docker.sh`, `Dockerfile-build-android`, `.dockerignore`: не переносить. Использовать `deploy/docker/run-docker.sh <variant>` или `docker compose -f deploy/docker/docker-compose.yml run --rm --build android` с `QGC_UID`/`QGC_GID`.
- `GSTREAMER_HOME`: не переносить. Использовать `-DGStreamer_ROOT_DIR=...`.
