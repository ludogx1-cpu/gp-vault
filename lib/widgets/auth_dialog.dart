import 'auth_dialog_widget.dart';
import 'package:flutter/material.dart';

void showAuthDialogGlobal(BuildContext context, bool isLogin) {
  showDialog(
    context: context,
    builder: (context) => AuthDialogWidget(isLogin: isLogin),
  );
}
