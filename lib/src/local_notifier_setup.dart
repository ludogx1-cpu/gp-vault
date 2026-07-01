import 'package:local_notifier/local_notifier.dart';

Future<void> setupLocalNotifier() async {
  await localNotifier.setup(
    appName: 'Golden Paw Vault',
    shortcutPolicy: ShortcutPolicy.requireCreate,
  );
}
