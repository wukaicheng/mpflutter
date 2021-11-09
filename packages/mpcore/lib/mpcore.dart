library mpcore;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:mpcore/mpkit/mpkit.dart';
import 'channel/channel_io.dart'
    if (dart.library.js) './channel/channel_js.dart';

export 'package:flutter/material.dart';
export './mpkit/mpkit.dart';
export './wechat_miniprogram/wechat_miniprogram.dart';

part 'document.dart';
part 'plugin.dart';
part './channel/channel_base.dart';
part './components/web_dialogs.dart';

class MPCore {
  static NavigatorObserver getNavigationObserver() {
    return MPNavigatorObserver.instance;
  }

  static final _plugins = <MPPlugin>[];

  static void registerPlugin(MPPlugin plugin) {
    _plugins.add(plugin);
  }

  Element get renderView => WidgetsBinding.instance!.renderViewElement!;

  void connectToHostChannel() async {}

  void injectErrorWidget() {}

  void injectMethodChannelHandler() {}

  Future handleHotReload() async {}

  static void clearOldFrameObject() {}

  static void cancelTextMeasureTask(String reason) {}

  Future sendFrame() async {}

  Future sendTextMeasureFrame() async {}

  Future nextFrame() async {}
}
