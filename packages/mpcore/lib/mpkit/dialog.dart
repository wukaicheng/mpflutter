part of 'mpkit.dart';

Future<T> showMPDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) async {
  final result = await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: builder);
  if (result is T) {
    return result;
  } else {
    throw 'Invalid resultType';
  }
}
