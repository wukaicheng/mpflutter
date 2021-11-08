import 'dart:io';

import '../mpcore.dart';

class MPChannel {
  static late HttpServer server;
  static List<WebSocket> sockets = [];

  static Future setupHotReload(MPCore minip) async {}

  static void setupWebServer() async {}

  static void handlePackageAssetsRequest(HttpRequest request) {}

  static String? findPackagePath(String pkgName) {}

  static void handleAssetsRequest(HttpRequest request) {}

  static void handleScaffoldRequest(HttpRequest request) {}

  static void postMessage(String message, {bool? forLastConnection}) {}

  static void postMapMessage(Map message, {bool? forLastConnection}) {}
}
