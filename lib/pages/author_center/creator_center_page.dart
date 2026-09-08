import 'package:flutter/material.dart';

import 'author_view.dart';

/// 保留旧入口，统一使用真实数据的创作者工作台。
class CreatorCenterPage extends StatelessWidget {
  const CreatorCenterPage({super.key});

  @override
  Widget build(BuildContext context) => const AuthorView();
}
