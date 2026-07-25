// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

bool hasBrowserHistory() {
  return html.window.history.length > 1;
}

void browserBack() {
  html.window.history.back();
}

void browserReplaceState(String path) {
  html.window.history.replaceState(null, '', path);
  html.window.dispatchEvent(html.PopStateEvent('popstate'));
}
