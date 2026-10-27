// ignore_for_file: non_constant_identifier_names

import 'package:app/config/share_channels.dart';

/// 外部渠道仅准备系统/网页编辑器，不代替用户发布，也不将海报假装作为附件发出。
Uri? share_channel_uri({
  required ShareChannelAction action,
  required Uri work_url,
  required String title,
}) => switch (action) {
  ShareChannelAction.whatsapp => Uri.https('wa.me', '/', {
    'text': '$title\n$work_url',
  }),
  ShareChannelAction.x => Uri.https('x.com', '/intent/tweet', {
    'text': title,
    'url': work_url.toString(),
  }),
  ShareChannelAction.telegram => Uri.https('t.me', '/share/url', {
    'url': work_url.toString(),
    'text': title,
  }),
  _ => null,
};
