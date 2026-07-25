import 'package:flutter/widgets.dart';

const double _pageHeaderToolbarHeight = 58;
const double _pageHeaderOverlap = 6;

double resolvePageHeaderContentTopPadding({
  required MediaQueryData mediaQuery,
  double headerBottomFadeSpacing = 0,
}) {
  final double safeTop = mediaQuery.padding.top;
  return safeTop +
      _pageHeaderToolbarHeight +
      headerBottomFadeSpacing -
      _pageHeaderOverlap;
}
