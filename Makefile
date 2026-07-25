# TODO 项目开发命令集
# 用法：make <命令>
# 所有命令执行前自动同步版本号

.PHONY: sync run run-web run-android run-ios build-apk build-ios clean

# TODO 默认命令
.DEFAULT_GOAL := help

# TODO 版本同步（内部调用）
sync:
	@bash scripts/sync_version.sh

# TODO 本地运行（自动选择设备）
run: sync
	fvm flutter run

# TODO 浏览器运行
run-web: sync
	fvm flutter run -d chrome

# TODO Android 运行
run-android: sync
	fvm flutter run -d android

# TODO iOS 运行
run-ios: sync
	fvm flutter run -d ios

# TODO 构建 APK
build-apk: sync
	fvm flutter build apk --release

# TODO 构建 iOS
build-ios: sync
	fvm flutter build ios --release

# TODO 构建 Web
build-web: sync
	fvm flutter build web

# TODO 清理构建缓存
clean:
	fvm flutter clean

# TODO 显示帮助
help:
	@echo "可用命令："
	@echo "  make run          - 本地运行（自动选择设备）"
	@echo "  make run-web      - 浏览器运行"
	@echo "  make run-android  - Android 运行"
	@echo "  make run-ios      - iOS 运行"
	@echo "  make build-apk    - 构建 APK"
	@echo "  make build-ios    - 构建 iOS"
	@echo "  make build-web    - 构建 Web"
	@echo "  make clean        - 清理构建缓存"
	@echo "  make sync         - 仅同步版本号"
