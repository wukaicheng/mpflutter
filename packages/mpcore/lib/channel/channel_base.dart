part of '../mpcore.dart';

bool requestingRoute = false;
String routeRequestId = '';

class MPNavigatorObserver extends NavigatorObserver {
  static final instance = MPNavigatorObserver();
  static bool doBacking = false;
  static bool initialPushed = false;

  String initialRoute = '/';
  Map initialParams = {};
  Map<int, Route> routeCache = {};
  Map<int, Size> routeViewport = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name?.startsWith('/mp_dialog/') == true) {
      return;
    }
    routeCache[route.hashCode] = route;
    if (requestingRoute) {
      final routeData = json.encode({
        'type': 'route',
        'message': {
          'event': 'responseRoute',
          'requestId': routeRequestId,
          'routeId': route.hashCode,
        },
      });
      MPChannel.postMessage(routeData);
      requestingRoute = false;
    } else {
      if (!initialPushed && previousRoute == null) {
        initialPushed = true;
        return;
      }
      final routeData = json.encode({
        'type': 'route',
        'message': {
          'event': 'didPush',
          'routeId': route.hashCode,
          'name': route.settings.name ?? '/',
          'params': (() {
            try {
              if (!(route.settings.arguments is Map)) return null;
              json.encode(route.settings.arguments);
              return route.settings.arguments;
            } catch (e) {
              return {};
            }
          })()
        },
      });
      MPChannel.postMessage(routeData);
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (doBacking) return;
    if (route.settings.name?.startsWith('/mp_dialog/') == true) {
      return;
    }
    final routeData = json.encode({
      'type': 'route',
      'message': {
        'event': 'didPop',
        'routeId': route.hashCode,
      },
    });
    MPChannel.postMessage(routeData);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routeCache.remove(route.hashCode);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null && oldRoute != null) {
      routeCache[newRoute.hashCode] = newRoute;
      if (requestingRoute) {
        final routeData = json.encode({
          'type': 'route',
          'message': {
            'event': 'responseRoute',
            'requestId': routeRequestId,
            'routeId': newRoute.hashCode,
          },
        });
        MPChannel.postMessage(routeData);
        requestingRoute = false;
      } else {
        final routeData = json.encode({
          'type': 'route',
          'message': {
            'event': 'didReplace',
            'routeId': newRoute.hashCode,
            'name': newRoute.settings.name ?? '/',
            'params': (() {
              try {
                if (!(newRoute.settings.arguments is Map)) return null;
                json.encode(newRoute.settings.arguments);
                return newRoute.settings.arguments;
              } catch (e) {
                return {};
              }
            })()
          },
        });
        MPChannel.postMessage(routeData);
      }
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class MPChannelBase {}
