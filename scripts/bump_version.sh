#!/bin/bash

# TODO 显式递增版本号脚本（发新版时手动调用）
# 版本号唯一来源为 pubspec.yaml，格式 X.Y.Z+N。
# 用法：
#   bash scripts/bump_version.sh build    # 仅 build number +1（同版本号内迭代/重新出包）
#   bash scripts/bump_version.sh patch    # 修订号 +1，build +1（如 1.2.3+24 → 1.2.4+25）
#   bash scripts/bump_version.sh minor    # 次版本 +1，build +1（如 1.2.3+24 → 1.3.0+25）
#   bash scripts/bump_version.sh major    # 主版本 +1，build +1（如 1.2.3+24 → 2.0.0+25）
# 注意：build（= 商店 versionCode = flutter_patcher 定位线上包的键）必须单调递增，
#       所以任何模式下 build 都只 +1、绝不重置。
#       热更打补丁期间不要动 version —— 打补丁请用 make patch-android/ios VC=<N>，不走本脚本。

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PUBSPEC_FILE="$PROJECT_DIR/pubspec.yaml"

MODE="${1:-}"

if [ -z "$MODE" ]; then
  echo "用法：bash scripts/bump_version.sh [build|patch|minor|major]"
  exit 1
fi

# TODO 读取并解析当前版本
VERSION_LINE=$(grep '^version:' "$PUBSPEC_FILE" || true)
if [ -z "$VERSION_LINE" ]; then
  echo "❌ pubspec.yaml 缺少 version 行"
  exit 1
fi

if ! echo "$VERSION_LINE" | grep -qE '^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$'; then
  echo "❌ version 格式错误：${VERSION_LINE}（必须为 X.Y.Z+N）"
  exit 1
fi

MAJOR=$(echo "$VERSION_LINE" | sed 's/^version: \([0-9]*\)\..*/\1/')
MINOR=$(echo "$VERSION_LINE" | sed 's/^version: [0-9]*\.\([0-9]*\)\..*/\1/')
PATCH=$(echo "$VERSION_LINE" | sed 's/^version: [0-9]*\.[0-9]*\.\([0-9]*\).*/\1/')
BUILD=$(echo "$VERSION_LINE" | sed 's/.*+\([0-9]*\).*/\1/')

case "$MODE" in
  build)
    BUILD=$((BUILD + 1))
    ;;
  patch)
    PATCH=$((PATCH + 1)); BUILD=$((BUILD + 1))
    ;;
  minor)
    MINOR=$((MINOR + 1)); PATCH=0; BUILD=$((BUILD + 1))
    ;;
  major)
    MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0; BUILD=$((BUILD + 1))
    ;;
  *)
    echo "❌ 未知模式：${MODE}（可选 build|patch|minor|major）"
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD"
sed -i '' "s/^version:.*/version: $NEW_VERSION/" "$PUBSPEC_FILE"

echo "✅ 版本已递增: $VERSION_LINE → version: $NEW_VERSION"
