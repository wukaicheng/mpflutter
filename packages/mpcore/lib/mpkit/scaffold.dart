part of 'mpkit.dart';

final List<MPScaffoldState> scaffoldStates = [];
final Map<int, MPScaffoldState> routeScaffoldStateMap = {};

class MPScaffold extends StatefulWidget {
  final String? name;
  final Color? appBarColor;
  final Color? appBarTintColor;
  final Widget? body;
  final Function? onRefresh;
  final Function(double)? onPageScroll;
  final Future<Map> Function()? onWechatMiniProgramShareAppMessage;
  final Function? onReachBottom;
  final PreferredSizeWidget? appBar;
  final Widget? bottomBar;
  final bool? bottomBarWithSafeArea;
  final Color? bottomBarSafeAreaColor;
  final Widget? floatingBody;
  final Color? backgroundColor;

  MPScaffold({
    this.name,
    this.appBarColor,
    this.appBarTintColor,
    this.body,
    this.onRefresh,
    this.onPageScroll,
    this.onWechatMiniProgramShareAppMessage,
    this.onReachBottom,
    this.appBar,
    this.bottomBar,
    this.bottomBarWithSafeArea,
    this.bottomBarSafeAreaColor,
    this.floatingBody,
    this.backgroundColor,
  });

  @override
  MPScaffoldState createState() => MPScaffoldState();
}

class MPScaffoldState extends State<MPScaffold> {
  void refreshState() {
    setState(() {});
  }

  Widget renderRefreshIndicator(Widget child) {
    return RefreshIndicator(
      child: child,
      onRefresh: () async {
        await widget.onRefresh?.call();
      },
    );
  }

  Widget renderReachBottomListener(Widget child) {
    return NotificationListener<ScrollNotification>(
      onNotification: (e) {
        if (e.metrics.atEdge && e.metrics.pixels > 0) {
          widget.onReachBottom?.call();
        }
        return false;
      },
      child: child,
    );
  }

  Widget renderOnPageScrollListener(Widget child) {
    return NotificationListener<ScrollNotification>(
      onNotification: (e) {
        widget.onPageScroll?.call(e.metrics.pixels);
        return false;
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    var body = widget.body ?? Container();
    if (widget.onReachBottom != null) {
      body = renderReachBottomListener(body);
    }
    if (widget.onPageScroll != null) {
      body = renderOnPageScrollListener(body);
    }
    if (widget.onRefresh != null) {
      body = renderRefreshIndicator(body);
    }
    if (widget.floatingBody != null) {
      body =
          Stack(children: [Positioned.fill(child: body), widget.floatingBody!]);
    }
    return Scaffold(
      appBar: (() {
        if (widget.appBar != null) {
          return widget.appBar;
        } else {
          return AppBar(
            title: Text(widget.name ?? ''),
            backgroundColor: widget.appBarColor,
            foregroundColor: widget.appBarTintColor,
          );
        }
      })(),
      backgroundColor: widget.backgroundColor,
      body: body,
      bottomNavigationBar: widget.bottomBar,
    );
  }
}

class MPOverlayScaffold extends MPScaffold {
  final bool? barrierDismissible;
  final Function? onBackgroundTap;
  final ModalRoute? parentRoute;

  MPOverlayScaffold({
    Widget? body,
    Color? backgroundColor,
    this.barrierDismissible,
    this.onBackgroundTap,
    this.parentRoute,
  }) : super(body: body, backgroundColor: backgroundColor);
}

class MPScaffoldBody extends StatelessWidget {
  final Widget? child;
  final double? appBarHeight;

  MPScaffoldBody({
    Key? key,
    this.child,
    this.appBarHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child ?? Container();
  }
}
