# TopRead 构建兼容补丁

来源：pub.dev `photo_manager 3.11.0`，保留 Apache-2.0 LICENSE。
发行包 SHA-256：`4f7de6c9778993c5c54cf1fb2eaa8d5c27c0771dc24a4dfca341aa81aef13fe1`。

本目录保留上游运行时源码、平台实现及说明文件；示例、测试和生成缓存未纳入。

## 回移修复

- 上游提交：[a36ec4c3c35c628a51113f24d3cc59cfba64654f](https://github.com/fluttercandies/flutter_photo_manager/commit/a36ec4c3c35c628a51113f24d3cc59cfba64654f)。
- 修改文件：`android/build.gradle`。
- 将旧 Kotlin 兼容分支的调用改为 `project.pluginManager.apply('kotlin-android')`。
- AGP 9 内置 Kotlin 模式下，该兼容分支不会执行；此修复避免 Flutter 静态扫描误判。

项目通过根 `pubspec.yaml` 中的 `dependency_overrides.photo_manager` 引用本目录。
官方发布包含该修复的版本后，检查更新日志和相册 API 兼容性，移除本地覆盖并更新锁文件。
