#!/usr/bin/env python3
"""从 Flutter 唯一调色板同步无法在运行时读取 Dart 的打包资源。

修改 lib/config/color_config.dart 后运行本脚本；CI 可用 --check 验证资源未漂移。
Android 按系统昼夜主题选择启动色，iOS 保留原有浅色启动画面，Web 保留安装主题。
原生广告颜色通过平台通道传入，不需要在此处生成第二份调色板。
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PALETTE_PATH = PROJECT_ROOT / "lib/config/color_config.dart"


def palette_values() -> dict[str, int]:
    """读取静态 Color 常量，并兼容已有常量别名，避免维护两份颜色数据。"""
    definitions = dict(
        re.findall(
            r"static\s+(?:const|final)\s+Color\s+(\w+)\s*=\s*(.*?);",
            PALETTE_PATH.read_text(),
            re.DOTALL,
        )
    )
    values: dict[str, int] = {}

    def resolve(name: str) -> int:
        if name in values:
            return values[name]
        expression = definitions[name].strip()
        literal = re.fullmatch(r"(?:const\s+)?Color\(\s*(0x[\da-fA-F]+|\d+)\s*\)", expression)
        legacy_hex = re.fullmatch(r'''hexToColor\(\s*["']#?([\da-fA-F]+)["']\s*\)''', expression)
        if literal:
            value = int(literal[1], 0)
        elif legacy_hex:
            hex_value = legacy_hex[1]
            value = int(("FF" if len(hex_value) == 6 else "") + hex_value, 16)
        else:
            alias = re.fullmatch(r"(?:ColorConstants\.)?(\w+)", expression)
            if not alias or alias[1] == name:
                raise ValueError(f"{name} 必须引用可静态解析的 Color 常量")
            value = resolve(alias[1])
        values[name] = value
        return value

    return {
        name: resolve(name)
        for name in ("whiteColor", "nightBackgroundColor", "web_manifest_theme")
    }


def generated_resources() -> dict[Path, str]:
    colors = palette_values()
    resources: dict[Path, str] = {}
    for qualifier, value in (
        ("values", colors["whiteColor"]),
        ("values-night", colors["nightBackgroundColor"]),
    ):
        resources[PROJECT_ROOT / f"android/app/src/main/res/{qualifier}/design_colors.xml"] = (
            '<?xml version="1.0" encoding="utf-8"?>\n'
            "<!-- 由 tool/sync_platform_colors.py 从 color_config.dart 生成，请勿手工改色。 -->\n"
            "<resources>\n"
            f'    <color name="app_launch_background">#{value:08X}</color>\n'
            "</resources>\n"
        )

    # 启动画面不能导入 Dart；在修改同一调色板后，将所需通道写回 Storyboard。
    value = colors["whiteColor"]
    channels = [(value >> shift & 255) / 255 for shift in (16, 8, 0, 24)]
    components = " ".join(
        f'{name}="{channel:.12g}"'
        for name, channel in zip(("red", "green", "blue", "alpha"), channels)
    )
    background = (
        f'<color key="backgroundColor" {components} '
        'colorSpace="custom" customColorSpace="sRGB"/>'
    )
    for name in ("Main", "LaunchScreen"):
        path = PROJECT_ROOT / f"ios/Runner/Base.lproj/{name}.storyboard"
        source = path.read_text()
        updated, count = re.subn(r'<color key="backgroundColor"[^>]*/>', background, source)
        if count != 1:
            raise ValueError(f"{path.name}: 预期恰好一个启动背景，实际为 {count}")
        resources[path] = updated

    manifest_path = PROJECT_ROOT / "web/manifest.json"
    manifest = json.loads(manifest_path.read_text())
    web_color = f'#{colors["web_manifest_theme"] & 0xFFFFFF:06X}'
    manifest["background_color"] = web_color
    manifest["theme_color"] = web_color
    resources[manifest_path] = json.dumps(manifest, ensure_ascii=False, indent=4) + "\n"
    return resources


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="只核验，发现漂移时返回非零退出码")
    arguments = parser.parse_args()
    stale: list[str] = []
    for path, expected in generated_resources().items():
        if path.exists() and path.read_text() == expected:
            continue
        stale.append(str(path.relative_to(PROJECT_ROOT)))
        if not arguments.check:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(expected)
    if arguments.check and stale:
        print("平台颜色资源与调色板不一致，请运行 python3 tool/sync_platform_colors.py：")
        print("\n".join(stale))
        return 1
    print(f"平台颜色资源已{'核验' if arguments.check else '同步'}；{len(stale)} 个文件需要更新。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
