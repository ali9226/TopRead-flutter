// ignore_for_file: non_constant_identifier_names

/// 分享弹窗、作品海报、选词海报的唯一渠道配置。
/// 调整此数组的顺序或 enabled 即可同步所有作品类型。
enum ShareChannelAction { generate_image, copy_link, whatsapp, x, telegram }

class ShareChannelDefinition {
  const ShareChannelDefinition({
    required this.id,
    required this.action,
    required this.icon_name,
    this.label = '',
    this.label_key = '',
    this.enabled = true,
  });

  final String id;
  final ShareChannelAction action;
  final String icon_name;
  final String label;
  final String label_key;
  final bool enabled;
}

const List<ShareChannelDefinition> share_channel_configuration = [
  ShareChannelDefinition(
    id: 'generate_image',
    action: ShareChannelAction.generate_image,
    icon_name: 'image',
    label_key: 'share_sheet.generate_image',
  ),
  ShareChannelDefinition(
    id: 'whatsapp',
    action: ShareChannelAction.whatsapp,
    icon_name: 'whats_app',
    label: 'WhatsApp',
    enabled: true,
  ),
  ShareChannelDefinition(
    id: 'x',
    action: ShareChannelAction.x,
    icon_name: 'x',
    label: 'X',
    enabled: true,
  ),
  ShareChannelDefinition(
    id: 'telegram',
    action: ShareChannelAction.telegram,
    icon_name: 'telegram',
    label: 'Telegram',
    enabled: true,
  ),
  ShareChannelDefinition(
    id: 'copy_link',
    action: ShareChannelAction.copy_link,
    icon_name: 'link',
    label_key: 'share_sheet.copy_link',
  ),
];

/// 已经位于海报预览时不再展示重复的“生成图片”入口。
List<ShareChannelDefinition> enabled_share_channels({
  bool include_generate_image = true,
}) => List.unmodifiable(
  share_channel_configuration.where(
    (channel) =>
        channel.enabled &&
        (include_generate_image ||
            channel.action != ShareChannelAction.generate_image),
  ),
);
