#!/bin/bash

# TODO 版本校验与 App 名称同步脚本
# 版本号唯一来源为 pubspec.yaml（constant.dart 运行时经 package_info_plus 读取），
# 本脚本只做校验，并把 constant.dart 的 app_name 同步到 pubspec 的 description / launcher_name。
# 用法：bash scripts/sync_version.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

CONSTANT_FILE="$PROJECT_DIR/lib/config/constant.dart"
PUBSPEC_FILE="$PROJECT_DIR/pubspec.yaml"

# TODO 从 constant.dart 提取 app_name 的值
APP_NAME=$(sed -n 's/.*static const String app_name = "\([^"]*\)".*/\1/p' "$CONSTANT_FILE")

if [ -z "$APP_NAME" ]; then
  echo "❌ 未找到 app_name，请检查 lib/config/constant.dart"
  exit 1
fi

# TODO 校验 pubspec.yaml 的 version 行存在且形如 X.Y.Z+N（flutter_patcher 依赖 build number 定位线上包）
VERSION_LINE=$(grep '^version:' "$PUBSPEC_FILE" || true)
if [ -z "$VERSION_LINE" ]; then
  echo "❌ pubspec.yaml 缺少 version 行"
  exit 1
fi

APP_VERSION=$(echo "$VERSION_LINE" | sed 's/^version: \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/')
BUILD_NUMBER=$(echo "$VERSION_LINE" | sed 's/.*+\([0-9]*\).*/\1/')

if ! echo "$VERSION_LINE" | grep -qE '^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$'; then
  echo "❌ version 格式错误：${VERSION_LINE}（必须为 X.Y.Z+N，N 为 build number）"
  exit 1
fi

# TODO 同步 app_name 到 pubspec.yaml 的 description 和 launcher_name
sed -i '' "s/^description:.*/description: \"$APP_NAME\"/" "$PUBSPEC_FILE"
sed -i '' "s/^\(  default:\).*/\1 \"$APP_NAME\"/" "$PUBSPEC_FILE"

echo "✅ 版本校验通过: ${APP_VERSION}+${BUILD_NUMBER}（唯一来源 pubspec.yaml）"
echo "✅ App名称已同步: $APP_NAME → description + launcher_name"
