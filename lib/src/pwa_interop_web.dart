import 'dart:js_interop';

@JS('canInstallPwa')
external JSBoolean _canInstallPwaJS();

@JS('triggerPwaInstall')
external void _triggerPwaInstallJS();

bool canInstallPwa() => _canInstallPwaJS().toDart;
void triggerPwaInstall() => _triggerPwaInstallJS();
