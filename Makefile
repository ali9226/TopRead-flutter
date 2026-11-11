# TODO 项目开发命令集
# 用法：make <命令>
# 所有命令执行前自动校验版本号并同步 App 名称

.PHONY: sync run run-web run-android run-ios build-apk build-ios build-web \
	release-android release-ios patch-android patch-ios withdraw-android withdraw-ios \
	patch-serve clean help

# TODO 默认命令
.DEFAULT_GOAL := help

# TODO 版本校验与 App 名称同步（内部调用）
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

# TODO 构建 APK（调试/测试用，不记录热更 baseline）
build-apk: sync
	fvm flutter build apk --release

# TODO 构建 iOS（调试/测试用，不记录热更 baseline）
build-ios: sync
	fvm flutter build ios --release

# TODO 构建 Web
build-web: sync
	fvm flutter build web

# TODO OBS 桥接保留 HTTPS 证书校验，并使用服务端原子禁止覆盖写入。
# TODO 另含源码软链守护，详见 scripts/patcher_run.sh 与 scripts/shims/aws；
# TODO 一键脚本 hot_patch.dart 会按 image_config 表的 region 覆盖本默认值
FLUTTER_PATCHER_S3_ENDPOINT ?= https://obs.af-south-1.myhuaweicloud.com
EXPORT_METHOD ?= app-store
ANDROID_FORMAT ?= both
export FLUTTER_PATCHER_S3_ENDPOINT
PATCHER_RUN := bash scripts/patcher_run.sh
PATCHER_OUT = $(if $(OUT),--out "$(OUT)",)
PATCHER_BASELINE = $(if $(BASELINE_STORE),--baseline-store "$(BASELINE_STORE)",)

# TODO 正式发版 Android（默认 AAB+APK；ANDROID_FORMAT=apk 可仅构建 APK）
release-android: sync
	$(PATCHER_RUN) fvm dart run flutter_patcher build android --android-format "$(ANDROID_FORMAT)" $(PATCHER_OUT) $(PATCHER_BASELINE)

# TODO 正式发版 iOS（flutter_patcher 构建，出包并记录 baseline，Apple Silicon Mac）
# TODO EXPORT_METHOD=development 可装自己手机（默认 app-store 提交商店）
release-ios: sync
	$(PATCHER_RUN) fvm dart run flutter_patcher build ios --export-method $(EXPORT_METHOD) $(PATCHER_OUT) $(PATCHER_BASELINE)

# TODO 打热更补丁 Android（VC=线上包的 build number）
# 用法：make patch-android VC=24
patch-android: sync
	@test -n "$(VC)" || (echo "❌ 缺少 VC 参数，用法：make patch-android VC=<build number>" && exit 1)
	$(PATCHER_RUN) fvm dart run flutter_patcher patch android --version-code $(VC) $(PATCHER_OUT) $(PATCHER_BASELINE)

# TODO 打热更补丁 iOS
# 用法：make patch-ios VC=24
patch-ios: sync
	@test -n "$(VC)" || (echo "❌ 缺少 VC 参数，用法：make patch-ios VC=<build number>" && exit 1)
	$(PATCHER_RUN) fvm dart run flutter_patcher patch ios --version-code $(VC) $(PATCHER_OUT) $(PATCHER_BASELINE)

# TODO 生成回滚文件 Android（把设备还原到未打补丁状态）
# 用法：make withdraw-android VC=24
withdraw-android: sync
	@test -n "$(VC)" || (echo "❌ 缺少 VC 参数，用法：make withdraw-android VC=<build number>" && exit 1)
	$(PATCHER_RUN) fvm dart run flutter_patcher patch android --version-code $(VC) --withdraw $(PATCHER_OUT) $(PATCHER_BASELINE)

# TODO 生成回滚文件 iOS
# 用法：make withdraw-ios VC=24
withdraw-ios: sync
	@test -n "$(VC)" || (echo "❌ 缺少 VC 参数，用法：make withdraw-ios VC=<build number>" && exit 1)
	$(PATCHER_RUN) fvm dart run flutter_patcher patch ios --version-code $(VC) --withdraw $(PATCHER_OUT) $(PATCHER_BASELINE)

# TODO 本地补丁调试服务（USB 连手机，开发期用）
patch-serve:
	$(PATCHER_RUN) fvm dart run flutter_patcher serve

# TODO 清理构建缓存
clean:
	fvm flutter clean

# TODO 显示帮助
help:
	@echo "可用命令："
	@echo "  make run              - 本地运行（自动选择设备）"
	@echo "  make run-web          - 浏览器运行"
	@echo "  make run-android      - Android 运行"
	@echo "  make run-ios          - iOS 运行"
	@echo "  make build-apk        - 构建 APK（测试用）"
	@echo "  make build-ios        - 构建 iOS（测试用）"
	@echo "  make build-web        - 构建 Web"
	@echo "  make release-android  - 正式发版 Android（记录热更 baseline）"
	@echo "  make release-ios      - 正式发版 iOS（记录热更 baseline）"
	@echo "  make patch-android VC=N  - 打热更补丁 Android"
	@echo "  make patch-ios VC=N      - 打热更补丁 iOS"
	@echo "  make withdraw-android VC=N - 生成回滚文件 Android"
	@echo "  make withdraw-ios VC=N     - 生成回滚文件 iOS"
	@echo "  make patch-serve      - 本地补丁调试服务"
	@echo "  make clean            - 清理构建缓存"
	@echo "  make sync             - 校验版本号并同步 App 名称"
