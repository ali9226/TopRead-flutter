#!/bin/bash

# TODO 同步版本号和App名称脚本
# 从 lib/config/constant.dart 读取 appVersion 和 app_name，更新 pubspec.yaml。
# 用法：bash scripts/sync_version.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

CONSTANT_FILE="$PROJECT_DIR/lib/config/constant.dart"
PUBSPEC_FILE="$PROJECT_DIR/pubspec.yaml"

# TODO 从 constant.dart 提取 appVersion 的值（兼容 macOS sed）
APP_VERSION=$(sed -n 's/.*static const String appVersion = "\([^"]*\)".*/\1/p' "$CONSTANT_FILE")

if [ -z "$APP_VERSION" ]; then
  echo "❌ 未找到 appVersion，请检查 lib/config/constant.dart"
  exit 1
fi

# TODO 从 constant.dart 提取 app_name 的值
APP_NAME=$(sed -n 's/.*static const String app_name = "\([^"]*\)".*/\1/p' "$CONSTANT_FILE")

if [ -z "$APP_NAME" ]; then
  echo "❌ 未找到 app_name，请检查 lib/config/constant.dart"
  exit 1
fi

# TODO 读取 pubspec.yaml 中现有的 version 行
OLD_VERSION_LINE=$(grep '^version:' "$PUBSPEC_FILE")

# TODO 提取旧的版本号和 build number
OLD_APP_VERSION=$(echo "$OLD_VERSION_LINE" | sed 's/version: \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/')
OLD_BUILD=$(echo "$OLD_VERSION_LINE" | sed 's/.*+\([0-9]*\).*/\1/')

# TODO 如果提取失败，默认值
if [ -z "$OLD_BUILD" ] || [ "$OLD_BUILD" = "$OLD_VERSION_LINE" ]; then
  OLD_BUILD=1
fi

# TODO 计算新的 build number（版本号变化时重置为 1，否则 +1）
if [ "$OLD_APP_VERSION" = "$APP_VERSION" ]; then
  NEW_BUILD=$((OLD_BUILD + 1))
else
  NEW_BUILD=1
fi

NEW_VERSION="version: $APP_VERSION+$NEW_BUILD"

# TODO 替换 pubspec.yaml 中的 version 行
sed -i '' "s/^version:.*/$NEW_VERSION/" "$PUBSPEC_FILE"

# TODO 同步 app_name 到 pubspec.yaml 的 description 和 launcher_name
sed -i '' "s/^description:.*/description: \"$APP_NAME\"/" "$PUBSPEC_FILE"
sed -i '' "s/^\(  default:\).*/\1 \"$APP_NAME\"/" "$PUBSPEC_FILE"

echo "✅ 版本已同步: $APP_VERSION+$NEW_BUILD"
echo "   constant.dart: $APP_VERSION"
echo "   pubspec.yaml:  $NEW_VERSION"
echo "✅ App名称已同步: $APP_NAME"
echo "   constant.dart:  $APP_NAME"
echo "   pubspec.yaml:   description + launcher_name"
