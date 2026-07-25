/* TODO 目录审查范围说明

# 1. 已纳入本轮人工整理范围

- `lib/`
- `assets/`
- `android/`
- `ios/`
- `linux/`
- `macos/`
- `windows/`
- `web/`
- `.github/`
- `资料/`
- `android_key/`

# 2. 只审查、不主动写入备注文件的目录

- `.git/`
- `.dart_tool/`
- `build/`
- `caches/`
- `daemon/`
- `native/`
- `wrapper/`
- `ios/Pods/`
- `ios/.symlinks/`
- `android/.gradle/`
- `android/build/`
- 各平台 `ephemeral`、`generated`、`outputs`、`intermediates` 目录

# 3. 原因

- 上述目录大多由 Flutter、Gradle、Xcode、CocoaPods、FVM 或系统工具生成。
- 在这些目录里补充说明文件或强行改名，会增加构建失败风险，也会污染自动生成内容。

# 4. 当前处理策略

- 人工维护目录：统一命名、补目录说明、持续清理注释与结构。
- 自动生成目录：保留原状，只记录用途和处理边界。
*/
