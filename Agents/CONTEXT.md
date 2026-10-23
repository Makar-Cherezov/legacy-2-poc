# Контекст задачи

## Учебная постановка
Занятие по Legacy-системам: перенести модификацию программы со старой версии на новую.
Команда студентов описала изменения форка и сделала тесты. Нужно:
реализовать описанные правки в новой версии, проверить их работоспособность
и **корректность самого описания**.

## Версии
| Что | Версия |
|---|---|
| Старая (база форка) | `mavlink/qgroundcontrol@495a17b4` (Stable_V4.4, Qt 5, qmake) |
| Новая (цель) | `mavlink/qgroundcontrol` ветка `Stable_V5.1` @ `07a764127` (Qt 6.11, только CMake) |
| Описание команды | https://gitlab.com/HappyPiece/legacy-2.git — `FORK_CHANGES_ANALYSIS.md`, `PROMT.md`, `tests/` |

Форк `qgc_fake` (старая версия + модификации) был у владельца локально; по решению владельца
старую версию не клонировали и **описанию команды доверяем** (с проверкой по коду V5.1).
Сам форк в этот репозиторий не входит. Перенос делали по исходникам форка (файлы `FlightPreparation*`),
адаптируя под API V5.1.

## Что входит в модификацию (по документу команды)
- **A. Flight Preparation** — read-only инструмент в Fly View: проверки ok/warning/unknown/info,
  сессионный чек-лист, заметка, текстовый отчёт, пороги в отдельной группе настроек.
- **B. Настройки видимости Fly View**: `showMapScale`, `showCameraControls`, `showTelemetryPanel`
  (`showMultiVehicleSelector` НЕ переносится — есть `appSettings.enableMultiVehiclePanel`).
- **C. GPS FactGroup** — `telemetryAvailable` уже исправлено в V5.1; рефакторинг не переносим.
- **D. Порядок пунктов меню** (MissionItemEditor, ParameterEditor) — по желанию, не сделано.
- **E. Docker/qmake/AppImage** — неприменимо/не переносить (в V5.1 нет qmake, есть свой docker-конвейер).
- **F. Переводы ru_RU** — неприменимо (Crowdin), `.ts` вручную не коммитить.

## Организация репозитория
- Корень — дерево QGroundControl `Stable_V5.1` + наши изменения. История начинается с импорта
  чистого V5.1 (первый коммит), затем коммиты с изменениями — `git log` / `git diff <первый коммит>` показывает только нашу работу.
- Работа ведётся в ветке `main` (или feature-ветках от неё).

## Ограничения среды владельца
Владелец (macOS arm64, только Command Line Tools) **не собирал проект** — нет Qt/CMake/Xcode.
Сборку и запуск тестов делает коллега на своём железе. Поэтому всё в PROGRESS.md помечено
«написано, но не скомпилировано», пока вы не подтвердите обратное в HANDOFF_LOG.md.

## Требуемое ПО для сборки и тестов
- Qt 6.11.1 (мин. 6.11.0) + модули: qtgraphs qtlocation qtpositioning qtspeech qtmultimedia qtserialport
  qtimageformats qtshadertools qtconnectivity qtquick3d qtsensors qtscxml qtwebsockets qthttpserver
  (включая `qmltestrunner`, `qmllint`)
- CMake ≥ 3.25, Ninja, Git, Python 3
- Компилятор: Xcode 16.x (macOS) / GCC или Clang (Linux) / MSVC 2022 (Windows)
- `just` ≥ 1.30 (необязательно)
- GStreamer 1.28.4 — только для видео
- Для ручной проверки UI: SITL PX4/ArduPilot
Источник версий: `.github/build-config.json`.
