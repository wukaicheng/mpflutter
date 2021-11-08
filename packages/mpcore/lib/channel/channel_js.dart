import 'dart:js' as js;

import '../mpcore.dart';

js.JsObject engineScope = js.context['engineScope'];
bool envSupportProxyObject = js.context['Proxy'] is js.JsFunction;

class MPChannel {
  static void setupHotReload(MPCore minip) async {}

  static void postMessage(String message, {bool? forLastConnection}) {}

  static void postMapMessage(Map message, {bool? forLastConnection}) {}
}
