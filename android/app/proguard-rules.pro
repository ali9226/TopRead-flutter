# ==================== R8 优化标志 ====================
# 将被混淆的类移到默认包，减少包名长度
-repackageclasses ''
# 允许更多访问修改以优化代码
-allowaccessmodification
# 合并相似的类
-mergeinterfacesaggressively
# 保留源文件名和行号（用于崩溃日志）
-keepattributes SourceFile,LineNumberTable
# 重命名源文件名为统一名称（保护隐私）
-renamesourcefileattribute SourceFile

# ==================== Flutter (最小必要保留) ====================
# Flutter 引擎入口和 Activity 必须保留
-keep class io.flutter.embedding.android.FlutterActivity { *; }
-keep class io.flutter.embedding.android.FlutterFragment { *; }
-keep class io.flutter.embedding.android.FlutterView { *; }
# Flutter 插件注册（通过反射调用）
-keep class io.flutter.plugins.** { *; }
# Flutter JNI
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keepclasseswithmembernames class io.flutter.** {
    native <methods>;
}

# ==================== Google Play Services ====================
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.common.api.GoogleApiClient { *; }
-keep class com.google.android.gms.common.ConnectionResult { *; }

# ==================== Google Play Core ====================
-dontwarn com.google.android.play.core.**

# ==================== Firebase ====================
-dontwarn com.google.firebase.**
# Firebase 通过反射初始化，需要保留入口
-keep class com.google.firebase.FirebaseApp { *; }
-keep class com.google.firebase.provider.FirebaseInitProvider { *; }
# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.android.gms.measurement.** { *; }

# ==================== Kotlin ====================
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ==================== Coroutines ====================
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }
-keepclassmembers class kotlin.coroutines.** { volatile <fields>; }

# ==================== AndroidX (仅保留必要的) ====================
-dontwarn androidx.**
# Lifecycle 组件（可能被反射使用）
-keep class androidx.lifecycle.** { *; }
# Activity/Fragment 基类
-keep class * extends androidx.activity.ComponentActivity { *; }
-keep class * extends androidx.fragment.app.Fragment { *; }

# ==================== 原生方法 ====================
-keepclasseswithmembernames class * {
    native <methods>;
}

# ==================== 枚举 ====================
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ==================== Parcelable ====================
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# ==================== Serializable ====================
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ==================== 应用入口 ====================
-keep class com.topread.novel.MainActivity { *; }

# ==================== AdMob ====================
-keep class com.google.android.gms.ads.** { *; }
-keepclassmembers class com.google.android.gms.ads.** { *; }

# ==================== FileProvider ====================
-keep class androidx.core.content.FileProvider { *; }

# ==================== Gson / JSON 序列化 ====================
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# ==================== GetX ====================
-keep class com.github.niclas_serializers.** { *; }
-keep class * extends com.github.niclas_serializers.** { *; }

# ==================== Dio ====================
-dontwarn io.fabianterhorst.**

# ==================== Google Sign-In ====================
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# ==================== WebView ====================
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# ==================== 其他库 ====================
-dontwarn me.leolin.shortcutbadger.**
-dontwarn com.google.errorprone.annotations.**
-dontnote
