import 'package:flutter/material.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/util/router/web_history.dart';

void routerBack(BuildContext context) {
  if (AppRouter.handleBack()) return;

  if (AppRouter.canPop()) {
    AppRouter.pop();
    return;
  }

  if (hasBrowserHistory()) {
    browserBack();
    return;
  }

  AppRouter.replace('/');
}
