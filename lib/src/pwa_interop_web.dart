import 'dart:js_interop';

@JS('canInstallPwa')
external JSBoolean _canInstallPwaJS();

@JS('triggerPwaInstall')
external void _triggerPwaInstallJS();

@JS('window.open')
external void _windowOpen(JSString url, JSString target);

bool canInstallPwa() => _canInstallPwaJS().toDart;
void triggerPwaInstall() => _triggerPwaInstallJS();
void downloadApk(String url) => _windowOpen(url.toJS, '_blank'.toJS);
