#!/usr/bin/env bash
set -euo pipefail

# 使用独立 Android 包运行真实场景，避免覆盖或停止正在调试的正式应用。
# 传入 adb serial 会安装、启动并输出逐帧统计；省略 serial 仅构建 APK。
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
profile_root="$(mktemp -d "${TMPDIR:-/tmp}/tile_quest_profile.XXXXXX")"
device_serial="${1:-}"
single_cpu="${TILE_QUEST_SINGLE_CPU:-false}"

cd "$project_root"
fvm flutter create --no-pub --platforms=android \
  --org=com.topread.profile --project-name=tile_quest_profile "$profile_root/project"

python3 - "$project_root" "$profile_root/project" <<'PY'
from pathlib import Path
import shutil
import sys

source, target = map(Path, sys.argv[1:])
(target / 'lib/pages').mkdir(parents=True, exist_ok=True)
shutil.copytree(source / 'lib/pages/tile_quest', target / 'lib/pages/tile_quest')
for relative in ['config/font_config.dart', 'util/device/app_environment.dart',
                 'util/storage_util/index.dart']:
    destination = target / 'lib' / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source / 'lib' / relative, destination)
# 基准入口采用英语，无需拉入正式应用的语言商店、登录和网络依赖。
language = target / 'lib/util/language_util/index.dart'
language.parent.mkdir(parents=True, exist_ok=True)
language.write_text('class LanguageUtil { static bool is_cjk_language(String code) '
                    "=> const ['zh', 'ja', 'ko'].contains(code); }\n")
# 与正式棋盘共用用户底板、背景和独立透明图标；不打包原始素材整图。
tile_assets = target / 'assets/img/tile_quest'
tile_assets.mkdir(parents=True, exist_ok=True)
for filename in ['lattice.png', 'background.png']:
    shutil.copy2(source / 'assets/img/tile_quest' / filename, tile_assets / filename)
for directory in ['icons', 'powerups']:
    shutil.copytree(source / 'assets/img/tile_quest' / directory, tile_assets / directory)
shutil.copy2(source / '.fvmrc', target / '.fvmrc')
shutil.copy2(source / 'tool/tile_quest_performance.dart', target / 'lib/main.dart')
(target / 'pubspec.yaml').write_text('''name: app
publish_to: none
version: 1.0.0+1
environment:
  sdk: ^3.11.5
dependencies:
  flutter:
    sdk: flutter
  get: ^4.7.2
  uuid: ^4.5.1
  get_storage: ^2.1.1
  easy_localization: ^3.0.7+1
  audioplayers: ^6.1.0
flutter:
  uses-material-design: true
  assets:
    - assets/img/tile_quest/lattice.png
    - assets/img/tile_quest/background.png
    - assets/img/tile_quest/icons/
    - assets/img/tile_quest/powerups/
''')
PY

cd "$profile_root/project"
fvm flutter pub get --offline
fvm flutter build apk --profile --no-pub --target-platform=android-arm64 \
  --dart-define="TILE_QUEST_SINGLE_CPU=$single_cpu"
profile_apk="$profile_root/project/build/app/outputs/flutter-apk/app-profile.apk"
printf '%s\n' "$profile_apk"
if [[ -n "$device_serial" ]]; then
  adb -s "$device_serial" install -r "$profile_apk"
  adb -s "$device_serial" shell am start \
    -n com.topread.profile.tile_quest_profile/.MainActivity
  python3 - "$device_serial" <<'PY_LOG'
import os
import selectors
import subprocess
import sys
import time

process = subprocess.Popen(
    ['adb', '-s', sys.argv[1], 'logcat', '-v', 'brief', '-T', '1',
     'flutter:I', '*:S'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    bufsize=0)
selector = selectors.DefaultSelector()
selector.register(process.stdout, selectors.EVENT_READ)
deadline = time.monotonic() + 120
completed = False
pending = b''
try:
    while time.monotonic() < deadline:
        if not selector.select(max(0, deadline - time.monotonic())):
            break
        chunk = os.read(process.stdout.fileno(), 65536)
        if not chunk:
            break
        pending += chunk
        while b'\n' in pending:
            raw_line, pending = pending.split(b'\n', 1)
            line = raw_line.decode('utf-8', errors='replace')
            if 'TILE_QUEST_PROFILE' in line:
                print(line.rstrip(), flush=True)
            if 'TILE_QUEST_PROFILE_DONE' in line:
                completed = True
                break
        if completed:
            break
finally:
    selector.close()
    process.terminate()
    try:
        process.wait(timeout=3)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
if not completed:
    raise SystemExit('Profile did not complete within 120 seconds.')
PY_LOG
fi
