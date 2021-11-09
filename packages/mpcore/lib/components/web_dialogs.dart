part of '../mpcore.dart';

enum ToastIcon {
  success,
  error,
  loading,
  none,
}

class PickerItem {
  final String label;
  final bool disabled;
  final List<PickerItem>? subItems;

  PickerItem({
    required this.label,
    this.disabled = false,
    this.subItems,
  });

  PickerItem.fromJson(Map<String, dynamic> json)
      : label = json['label'],
        disabled = json['disabled'],
        subItems = json['subItems'];

  Map toJson() {
    return {
      'label': label,
      'disabled': disabled,
      'subItems': subItems,
    };
  }
}

class MPWebDialogs {
  static BuildContext? currentContext() {
    return MPCore.getNavigationObserver().navigator?.context;
  }

  static Future alert({required String message}) async {
    final context = currentContext();
    if (context == null) return null;
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            MaterialButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('好的'),
            )
          ],
        );
      },
    );
  }

  static Future<bool> confirm({required String message}) async {
    final context = currentContext();
    if (context == null) return false;
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              minWidth: 44,
              child: Text('取消'),
            ),
            MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              minWidth: 44,
              child: Text(
                '确认',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<String?> prompt(
      {required String message, String? defaultValue}) async {
    final context = currentContext();
    if (context == null) return null;
    return await showDialog(
      context: context,
      builder: (context) {
        final editingController = TextEditingController();
        editingController.text = defaultValue ?? '';
        return AlertDialog(
          title: Text(
            message,
            style: TextStyle(fontSize: 16),
          ),
          content: TextField(
            controller: editingController,
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              minWidth: 44,
              child: Text('取消'),
            ),
            MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(editingController.text);
              },
              minWidth: 44,
              child: Text(
                '确认',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<int?> actionSheet({required List<String> items}) async {
    final context = currentContext();
    if (context == null) return null;
    final widgets = <Widget>[];
    widgets.addAll(items
        .asMap()
        .map((key, value) {
          return MapEntry(
            key,
            Column(
              children: [
                ListTile(
                  title: Center(child: Text(value)),
                  onTap: () {
                    Navigator.of(context).pop(key);
                  },
                ),
                Divider(height: 1)
              ],
            ),
          );
        })
        .values
        .toList());
    widgets.add(ListTile(
      title: Center(child: Text('取消')),
      onTap: () {
        Navigator.of(context).pop(null);
      },
    ));
    return await showModalBottomSheet(
      context: context,
      isDismissible: true,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: widgets,
        );
      },
    );
  }

  static BuildContext? activeToast;

  static void showToast({
    required String title,
    ToastIcon? icon,
    Duration duration = const Duration(milliseconds: 1500),
    bool mask = false,
  }) {
    final context = currentContext();
    if (context == null) return null;
    hideToast();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) {
        activeToast = context;
        Future.delayed(duration).then((_) {
          if (activeToast == context) {
            hideToast();
          }
        });
        return _ToastWidget(
          title: title,
          icon: icon,
        );
      },
    );
  }

  static void hideToast() {
    if (activeToast != null) {
      final route = ModalRoute.of(activeToast!);
      route?.navigator?.removeRoute(route);
      activeToast = null;
    }
  }

  static void showLoading({
    required String title,
    bool mask = false,
  }) {
    showToast(
      title: title,
      icon: ToastIcon.loading,
      duration: Duration(seconds: 3600),
      mask: mask,
    );
  }

  static void hideLoading() {
    hideToast();
  }

  static Future<List?> showPicker({
    required String title,
    required List<PickerItem> items,
    String? confirmText,
    List<num>? disabledIds,
  }) async {}

  static Future<List?> showDatePicker({
    required int start,
    required int end,
    List? defaultValue,
  }) async {}
}

class _ToastWidget extends StatelessWidget {
  final String title;
  final ToastIcon? icon;

  _ToastWidget({
    required this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: BoxConstraints(
                minWidth: 120, minHeight: icon != null ? 120 : 60),
            color: Colors.black.withOpacity(0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon != null
                    ? (() {
                        if (icon == ToastIcon.loading) {
                          return Container(
                            constraints:
                                BoxConstraints(maxWidth: 28, maxHeight: 28),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        } else if (icon == ToastIcon.none) {
                          return SizedBox(height: 0);
                        } else {
                          return Icon(
                            (() {
                              switch (icon) {
                                case ToastIcon.error:
                                  return Icons.error;
                                case ToastIcon.success:
                                  return Icons.check;
                                default:
                                  throw 'No icons';
                              }
                            })(),
                            size: 48,
                            color: Colors.white,
                          );
                        }
                      })()
                    : SizedBox(height: 0),
                title.isNotEmpty && icon != null
                    ? SizedBox(height: 12)
                    : SizedBox(height: 0),
                title.isNotEmpty
                    ? Text(
                        title,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      )
                    : SizedBox(height: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
