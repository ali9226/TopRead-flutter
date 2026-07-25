

# 打包APK
    flutter build apk --release

# 打包abb文件
    flutter build appbundle --release

# 分版本打包
    flutter build apk --release --split-per-abi --split-debug-info=build/symbols

# 安装到手机
    adb install /Users/ali/work/小说/app/build/app/outputs/flutter-apk/app-release.apk

# 安装到手机(分版本)
    adb install /Users/ali/work/小说/app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk


# 生成ios内测包
    fvm flutter build ipa

# 开启日志
    adb logcat -s flutter

# 运行web端并且关闭校验
    flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev"

# 在浏览器端运行，指定端口，允许比如127.0.0.1或者本地ip等访问
    flutter run -d web-server --web-hostname=0.0.0.0 --web-port=56670
