# android

当前目录用途：Android 原生工程目录。

## 构建工具版本

- Gradle 9.3.1：由 `gradle/wrapper/gradle-wrapper.properties` 固定，并校验发行包 SHA-256。
- Android Gradle Plugin 9.1.1、Kotlin 2.4.21：在 `settings.gradle.kts` 统一声明。
- JDK 17：通过 `fvm flutter config --jdk-dir=<JDK 17 路径>` 设置 Flutter 使用的 JDK。
- Java 与 Kotlin 的 JVM target 统一为 17。

Kotlin 由 Gradle 解析和下载，无需单独安装编译器。应用使用 AGP 内置 Kotlin；
`settings.gradle.kts` 中的 Kotlin `apply false` 用于统一编译器版本。
`gradlew --version` 显示的 Kotlin 是 Gradle 自带的 Kotlin DSL 版本，项目编译器版本以该声明为准。
暂时保留 `android.newDsl=false` 以兼容现有 Flutter 插件。

IDEA 使用项目的 FVM Flutter SDK，并通过项目 Gradle Wrapper 构建。
修改版本配置后重新同步 Gradle，再运行 `lib/main.dart`。
切换 debug/release 构建时保留默认的 pub 步骤，以重新生成对应模式的原生插件注册清单。

维护约束：
- 目录名与文件名统一使用小写英文和下划线。
- Dart 页面目录优先遵循 `index.dart / logic.dart / style.dart`。
- 公共能力优先抽离，避免重复代码继续堆积在当前目录。
- 当前目录的说明文档由整库整理流程自动补齐，后续变更时应同步更新。
