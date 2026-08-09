## iOS Universal Links 配置指南

### 1. 上传 AASA 文件到服务器

将 `apple-app-site-association` 文件放到服务器：

/www/wwwroot/read.top/.well-known/apple-app-site-association

注意：文件名不带 .json 后缀。

### 2. 更新 nginx 配置

用 `nginx.conf` 里的内容替换你现有的 nginx 配置，然后重载 nginx：

nginx -t && nginx -s reload

### 3. 验证 AASA 文件

在浏览器访问：

https://www.read.top/.well-known/apple-app-site-association

应该能看到 JSON 内容，且 Content-Type 为 application/json。

也可以用命令验证：

curl -I https://www.read.top/.well-known/apple-app-site-association

### 4. iOS App 端配置

在 Xcode 中：
1. 选择 Runner Target
2. Signing & Capabilities → + Capability → Associated Domains
3. 添加：applinks:www.read.top

### 5. 测试

在 Safari 中访问 https://www.read.top/story/xxx，如果 App 已安装会打开 App，未安装则在 Safari 中打开网页。
