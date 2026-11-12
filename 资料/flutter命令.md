

# 打包APK
    fvm flutter build apk --release

# 打包abb文件
    fvm flutter build appbundle --release

# 打包abb文件支持热更新的版本
    HOT_PATCH_OBS_DIRECT=1 fvm dart run scripts/hot_patch.dart release --prod --os android --android-format both

# 分版本打包
    flutter build apk --release --split-per-abi --split-debug-info=build/symbols

# 安装到手机
    adb install /Users/ali/work/小说/app/build/app/outputs/flutter-apk/app-release.apk

# 安装到手机(分版本)
    adb install /Users/ali/work/小说/app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk


# 生成ios内测包
    fvm flutter build ipa

# 生成可以热更新的内测包
    HOT_PATCH_OBS_DIRECT=1 fvm dart run scripts/hot_patch.dart release --prod --os ios

# 生成热更新的补丁
    HOT_PATCH_OBS_DIRECT=1 fvm dart run scripts/hot_patch.dart patch --prod --os ios --vc 30 --remark '第二个补丁：测试补丁'



# 开启日志
    adb logcat -s flutter

# ios运行卡顿，查看卡住日志
    cd ./ios && pod install --verbose

# 运行web端并且关闭校验
    flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev"

# 在浏览器端运行，指定端口，允许比如127.0.0.1或者本地ip等访问
    flutter run -d web-server --web-hostname=0.0.0.0 --web-port=56670
