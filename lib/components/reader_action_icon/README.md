# 阅读操作图标

长篇、短篇与漫画底栏共用的单色 SVG 渲染组件。目录使用 `qr_code`，评论使用 `customer_service`，调用方仍持有原有标签和业务回调。

此组件通过 `ColorFilter` 覆盖 SVG 内置填色，不改变全局多色 `SvgIcon` 的行为。
