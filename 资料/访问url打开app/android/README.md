## Android App Links 配置指南

### 1. 上传 assetlinks.json 到服务器

将 `assetlinks.json` 文件放到服务器：

/www/wwwroot/read.top/.well-known/assetlinks.json

nginx 已配置 .well-known 目录可访问，无需额外修改。

### 2. 验证 assetlinks.json

在浏览器访问：

https://www.read.top/.well-known/assetlinks.json

应该能看到 JSON 内容。

### 3. Android 端配置已完成

AndroidManifest.xml 已添加 intent-filter：
- android:autoVerify="true" 让系统自动验证
- android:host="www.read.top" 匹配域名
- android:scheme="https" 使用 HTTPS 协议

### 4. 获取正式版 SHA256 指纹

当前 assetlinks.json 使用的是 debug 签名的 SHA256 指纹。

发布前需要用正式签名的 SHA256 替换：

keytool -list -v -keystore your-release-key.keystore -alias your-alias

将输出的 SHA256 指纹替换到 assetlinks.json 中。

注意：可以同时保留 debug 和 release 指纹，方便开发调试。

### 5. 测试

在 Chrome 中访问 https://www.read.top/story/xxx，如果 App 已安装会弹出"用 TopRead 打开"的提示。
