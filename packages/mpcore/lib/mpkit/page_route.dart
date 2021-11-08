part of 'mpkit.dart';

class MPPageRoute<T> extends MaterialPageRoute<T> {
  MPPageRoute({RouteSettings? settings, required WidgetBuilder builder})
      : super(builder: builder, settings: settings);
}
