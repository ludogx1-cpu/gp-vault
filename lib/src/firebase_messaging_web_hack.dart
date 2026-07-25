import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_messaging_web/firebase_messaging_web.dart';

void registerFirebaseMessagingWeb() {
  FirebaseMessagingWeb.registerWith(webPluginRegistrar);
}
