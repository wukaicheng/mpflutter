// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material_adapter.dart';
import 'package:flutter/ui/ui.dart' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/widgets.dart' hide Colors;

import 'app_bar.dart';
import 'banner.dart';
import 'bottom_sheet.dart';
import 'colors.dart';
import 'curves.dart';
import 'debug.dart';
import 'divider.dart';
import 'flexible_space_bar.dart';
import 'floating_action_button.dart';
import 'floating_action_button_location.dart';
import 'material.dart';
import 'snack_bar.dart';
import 'snack_bar_theme.dart';
import 'theme.dart';

// Examples can assume:
// late TabController tabController;
// void setState(VoidCallback fn) { }
// late String appBarTitle;
// late int tabCount;
// late TickerProvider tickerProvider;

const FloatingActionButtonLocation _kDefaultFloatingActionButtonLocation =
    FloatingActionButtonLocation.endFloat;
const FloatingActionButtonAnimator _kDefaultFloatingActionButtonAnimator =
    FloatingActionButtonAnimator.scaling;

const Curve _standardBottomSheetCurve = standardEasing;
// When the top of the BottomSheet crosses this threshold, it will start to
// shrink the FAB and show a scrim.
const double _kBottomSheetDominatesPercentage = 0.3;
const double _kMinBottomSheetScrimOpacity = 0.1;
const double _kMaxBottomSheetScrimOpacity = 0.6;

enum _ScaffoldSlot {
  body,
  appBar,
  bodyScrim,
  bottomSheet,
  snackBar,
  materialBanner,
  persistentFooter,
  bottomNavigationBar,
  floatingActionButton,
  drawer,
  endDrawer,
  statusBar,
}

/// Manages [SnackBar]s for descendant [Scaffold]s.
///
/// This class provides APIs for showing snack bars.
///
/// To display a snack bar, obtain the [ScaffoldMessengerState] for the current
/// [BuildContext] via [ScaffoldMessenger.of] and use the
/// [ScaffoldMessengerState.showSnackBar] function.
///
/// When the [ScaffoldMessenger] has nested [Scaffold] descendants, the
/// ScaffoldMessenger will only present a [SnackBar] to the root Scaffold of
/// the subtree of Scaffolds. In order to show SnackBars in the inner, nested
/// Scaffolds, set a new scope for your SnackBars by instantiating a new
/// ScaffoldMessenger in between the levels of nesting.
///
/// {@tool dartpad --template=stateless_widget_scaffold_center}
///
/// Here is an example of showing a [SnackBar] when the user presses a button.
///
/// ```dart
///   Widget build(BuildContext context) {
///     return OutlinedButton(
///       onPressed: () {
///         ScaffoldMessenger.of(context).showSnackBar(
///           const SnackBar(
///             content: Text('A SnackBar has been shown.'),
///           ),
///         );
///       },
///       child: const Text('Show SnackBar'),
///     );
///   }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [SnackBar], which is a temporary notification typically shown near the
///    bottom of the app using the [ScaffoldMessengerState.showSnackBar] method.
///  * [debugCheckHasScaffoldMessenger], which asserts that the given context
///    has a [ScaffoldMessenger] ancestor.
///  * Cookbook: [Display a SnackBar](https://flutter.dev/docs/cookbook/design/snackbars)
class ScaffoldMessenger extends StatefulWidget {
  /// Creates a widget that manages [SnackBar]s for [Scaffold] descendants.
  const ScaffoldMessenger({
    Key? key,
    required this.child,
  })  : assert(child != null),
        super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// {@tool dartpad --template=stateless_widget_scaffold_center}
  /// Typical usage of the [ScaffoldMessenger.of] function is to call it in
  /// response to a user gesture or an application state change.
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return ElevatedButton(
  ///     child: const Text('SHOW A SNACKBAR'),
  ///     onPressed: () {
  ///       ScaffoldMessenger.of(context).showSnackBar(
  ///         const SnackBar(
  ///           content: Text('Have a snack!'),
  ///         ),
  ///       );
  ///     },
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// A less elegant but more expedient solution is to assign a [GlobalKey] to the
  /// [ScaffoldMessenger], then use the `key.currentState` property to obtain the
  /// [ScaffoldMessengerState] rather than using the [ScaffoldMessenger.of]
  /// function. The [MaterialApp.scaffoldMessengerKey] refers to the root
  /// ScaffoldMessenger that is provided by default.
  ///
  /// {@tool dartpad --template=freeform}
  /// Sometimes [SnackBar]s are produced by code that doesn't have ready access
  /// to a valid [BuildContext]. One such example of this is when you show a
  /// SnackBar from a method outside of the `build` function. In these
  /// cases, you can assign a [GlobalKey] to the [ScaffoldMessenger]. This
  /// example shows a key being used to obtain the [ScaffoldMessengerState]
  /// provided by the [MaterialApp].
  ///
  /// ```dart imports
  /// import 'package:flutter/material.dart';
  /// ```
  /// ```dart
  /// void main() => runApp(const MyApp());
  ///
  /// class MyApp extends StatefulWidget {
  ///   const MyApp({Key? key}) : super(key: key);
  ///
  ///   @override
  ///  State<MyApp> createState() => _MyAppState();
  /// }
  ///
  /// class _MyAppState extends State<MyApp> {
  ///   final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  ///   int _counter = 0;
  ///
  ///   void _incrementCounter() {
  ///     setState(() {
  ///       _counter++;
  ///     });
  ///     if (_counter % 10 == 0) {
  ///       _scaffoldMessengerKey.currentState!.showSnackBar(const SnackBar(
  ///         content: Text('A multiple of ten!'),
  ///       ));
  ///     }
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return MaterialApp(
  ///       scaffoldMessengerKey: _scaffoldMessengerKey,
  ///       home: Scaffold(
  ///         appBar: AppBar(title: const Text('ScaffoldMessenger Demo')),
  ///         body: Center(
  ///           child: Column(
  ///             mainAxisAlignment: MainAxisAlignment.center,
  ///             children: <Widget>[
  ///               const Text(
  ///                 'You have pushed the button this many times:',
  ///               ),
  ///               Text(
  ///                 '$_counter',
  ///                 style: Theme.of(context).textTheme.headline4,
  ///               ),
  ///             ],
  ///           ),
  ///         ),
  ///         floatingActionButton: FloatingActionButton(
  ///           onPressed: _incrementCounter,
  ///           tooltip: 'Increment',
  ///           child: Icon(Icons.add),
  ///         ),
  ///       ),
  ///     );
  ///   }
  /// }
  ///
  /// ```
  /// {@end-tool}
  ///
  /// If there is no [ScaffoldMessenger] in scope, then this will assert in
  /// debug mode, and throw an exception in release mode.
  ///
  /// See also:
  ///
  ///  * [maybeOf], which is a similar function but will return null instead of
  ///    throwing if there is no [ScaffoldMessenger] ancestor.
  ///  * [debugCheckHasScaffoldMessenger], which asserts that the given context
  ///    has a [ScaffoldMessenger] ancestor.
  static ScaffoldMessengerState of(BuildContext context) {
    assert(context != null);
    assert(debugCheckHasScaffoldMessenger(context));

    final _ScaffoldMessengerScope scope =
        context.dependOnInheritedWidgetOfExactType<_ScaffoldMessengerScope>()!;
    return scope._scaffoldMessengerState;
  }

  /// The state from the closest instance of this class that encloses the given
  /// context, if any.
  ///
  /// Will return null if a [ScaffoldMessenger] is not found in the given context.
  ///
  /// See also:
  ///
  ///  * [of], which is a similar function, except that it will throw an
  ///    exception if a [ScaffoldMessenger] is not found in the given context.
  static ScaffoldMessengerState? maybeOf(BuildContext context) {
    assert(context != null);

    final _ScaffoldMessengerScope? scope =
        context.dependOnInheritedWidgetOfExactType<_ScaffoldMessengerScope>();
    return scope?._scaffoldMessengerState;
  }

  @override
  ScaffoldMessengerState createState() => ScaffoldMessengerState();
}

/// State for a [ScaffoldMessenger].
///
/// A [ScaffoldMessengerState] object can be used to [showSnackBar] for every
/// registered [Scaffold] that is a descendant of the associated
/// [ScaffoldMessenger]. Scaffolds will register to receive [SnackBar]s from
/// their closest ScaffoldMessenger ancestor.
///
/// Typically obtained via [ScaffoldMessenger.of].
class ScaffoldMessengerState extends State<ScaffoldMessenger>
    with TickerProviderStateMixin {
  final Queue<
      ScaffoldFeatureController<MaterialBanner,
          MaterialBannerClosedReason>> _materialBanners = Queue<
      ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>>();
  AnimationController? _materialBannerController;
  final Queue<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>>
      _snackBars =
      Queue<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>>();
  AnimationController? _snackBarController;
  Timer? _snackBarTimer;
  bool? _accessibleNavigation;

  @override
  void didChangeDependencies() {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    // If we transition from accessible navigation to non-accessible navigation
    // and there is a SnackBar that would have timed out that has already
    // completed its timer, dismiss that SnackBar. If the timer hasn't finished
    // yet, let it timeout as normal.
    if (_accessibleNavigation == true &&
        !mediaQuery.accessibleNavigation &&
        _snackBarTimer != null &&
        !_snackBarTimer!.isActive) {
      hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
    }
    _accessibleNavigation = mediaQuery.accessibleNavigation;
    super.didChangeDependencies();
  }

  void _updateScaffolds() {}

  // SNACKBAR API

  /// Shows  a [SnackBar] across all registered [Scaffold]s.
  ///
  /// A scaffold can show at most one snack bar at a time. If this function is
  /// called while another snack bar is already visible, the given snack bar
  /// will be added to a queue and displayed after the earlier snack bars have
  /// closed.
  ///
  /// To control how long a [SnackBar] remains visible, use [SnackBar.duration].
  ///
  /// To remove the [SnackBar] with an exit animation, use [hideCurrentSnackBar]
  /// or call [ScaffoldFeatureController.close] on the returned
  /// [ScaffoldFeatureController]. To remove a [SnackBar] suddenly (without an
  /// animation), use [removeCurrentSnackBar].
  ///
  /// See [ScaffoldMessenger.of] for information about how to obtain the
  /// [ScaffoldMessengerState].
  ///
  /// {@tool dartpad --template=stateless_widget_scaffold_center}
  ///
  /// Here is an example of showing a [SnackBar] when the user presses a button.
  ///
  /// ```dart
  ///   Widget build(BuildContext context) {
  ///     return OutlinedButton(
  ///       onPressed: () {
  ///         ScaffoldMessenger.of(context).showSnackBar(
  ///           const SnackBar(
  ///             content: Text('A SnackBar has been shown.'),
  ///           ),
  ///         );
  ///       },
  ///       child: const Text('Show SnackBar'),
  ///     );
  ///   }
  /// ```
  /// {@end-tool}
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
      SnackBar snackBar) {
    _snackBarController ??= SnackBar.createAnimationController(vsync: this)
      ..addStatusListener(_handleSnackBarStatusChanged);
    if (_snackBars.isEmpty) {
      assert(_snackBarController!.isDismissed);
      _snackBarController!.forward();
    }
    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
    controller = ScaffoldFeatureController<SnackBar, SnackBarClosedReason>._(
      // We provide a fallback key so that if back-to-back snackbars happen to
      // match in structure, material ink splashes and highlights don't survive
      // from one to the next.
      snackBar.withAnimation(_snackBarController!, fallbackKey: UniqueKey()),
      Completer<SnackBarClosedReason>(),
      () {
        assert(_snackBars.first == controller);
        hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
      },
      null, // SnackBar doesn't use a builder function so setState() wouldn't rebuild it
    );
    setState(() {
      _snackBars.addLast(controller);
    });
    _updateScaffolds();
    return controller;
  }

  void _handleSnackBarStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        assert(_snackBars.isNotEmpty);
        setState(() {
          _snackBars.removeFirst();
        });
        _updateScaffolds();
        if (_snackBars.isNotEmpty) {
          _snackBarController!.forward();
        }
        break;
      case AnimationStatus.completed:
        setState(() {
          assert(_snackBarTimer == null);
          // build will create a new timer if necessary to dismiss the snackBar.
        });
        _updateScaffolds();
        break;
      case AnimationStatus.forward:
        break;
      case AnimationStatus.reverse:
        break;
    }
  }

  /// Removes the current [SnackBar] (if any) immediately from registered
  /// [Scaffold]s.
  ///
  /// The removed snack bar does not run its normal exit animation. If there are
  /// any queued snack bars, they begin their entrance animation immediately.
  void removeCurrentSnackBar(
      {SnackBarClosedReason reason = SnackBarClosedReason.remove}) {
    assert(reason != null);
    if (_snackBars.isEmpty) return;
    final Completer<SnackBarClosedReason> completer =
        _snackBars.first._completer;
    if (!completer.isCompleted) completer.complete(reason);
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    // This will trigger the animation's status callback.
    _snackBarController!.value = 0.0;
  }

  /// Removes the current [SnackBar] by running its normal exit animation.
  ///
  /// The closed completer is called after the animation is complete.
  void hideCurrentSnackBar(
      {SnackBarClosedReason reason = SnackBarClosedReason.hide}) {
    assert(reason != null);
    if (_snackBars.isEmpty ||
        _snackBarController!.status == AnimationStatus.dismissed) return;
    final Completer<SnackBarClosedReason> completer =
        _snackBars.first._completer;
    if (_accessibleNavigation!) {
      _snackBarController!.value = 0.0;
      completer.complete(reason);
    } else {
      _snackBarController!.reverse().then<void>((void value) {
        assert(mounted);
        if (!completer.isCompleted) completer.complete(reason);
      });
    }
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
  }

  /// Removes all the snackBars currently in queue by clearing the queue
  /// and running normal exit animation on the current snackBar.
  void clearSnackBars() {
    if (_snackBars.isEmpty ||
        _snackBarController!.status == AnimationStatus.dismissed) return;
    final ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
        currentSnackbar = _snackBars.first;
    _snackBars.clear();
    _snackBars.add(currentSnackbar);
    hideCurrentSnackBar();
  }

  // MATERIAL BANNER API

  /// Shows a [MaterialBanner] across all registered [Scaffold]s.
  ///
  /// A scaffold can show at most one material banner at a time. If this function is
  /// called while another material banner is already visible, the given material banner
  /// will be added to a queue and displayed after the earlier material banners have
  /// closed.
  ///
  /// To remove the [MaterialBanner] with an exit animation, use [hideCurrentMaterialBanner]
  /// or call [ScaffoldFeatureController.close] on the returned
  /// [ScaffoldFeatureController]. To remove a [MaterialBanner] suddenly (without an
  /// animation), use [removeCurrentMaterialBanner].
  ///
  /// See [ScaffoldMessenger.of] for information about how to obtain the
  /// [ScaffoldMessengerState].
  ///
  /// {@tool dartpad --template=stateless_widget_scaffold_center}
  ///
  /// Here is an example of showing a [MaterialBanner] when the user presses a button.
  ///
  /// ```dart
  ///   Widget build(BuildContext context) {
  ///     return OutlinedButton(
  ///       onPressed: () {
  ///         ScaffoldMessenger.of(context).showMaterialBanner(
  ///           const MaterialBanner(
  ///             content: Text('This is a MaterialBanner'),
  ///             actions: <Widget>[
  ///               TextButton(
  ///                 child: Text('DISMISS'),
  ///                 onPressed: null,
  ///               ),
  ///             ],
  ///           ),
  ///         );
  ///       },
  ///       child: const Text('Show MaterialBanner'),
  ///     );
  ///   }
  /// ```
  /// {@end-tool}
  ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
      showMaterialBanner(MaterialBanner materialBanner) {
    _materialBannerController ??=
        MaterialBanner.createAnimationController(vsync: this)
          ..addStatusListener(_handleMaterialBannerStatusChanged);
    if (_materialBanners.isEmpty) {
      assert(_materialBannerController!.isDismissed);
      _materialBannerController!.forward();
    }
    late ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
        controller;
    controller =
        ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>._(
      // We provide a fallback key so that if back-to-back material banners happen to
      // match in structure, material ink splashes and highlights don't survive
      // from one to the next.
      materialBanner.withAnimation(_materialBannerController!,
          fallbackKey: UniqueKey()),
      Completer<MaterialBannerClosedReason>(),
      () {
        assert(_materialBanners.first == controller);
        hideCurrentMaterialBanner(reason: MaterialBannerClosedReason.hide);
      },
      null, // MaterialBanner doesn't use a builder function so setState() wouldn't rebuild it
    );
    setState(() {
      _materialBanners.addLast(controller);
    });
    _updateScaffolds();
    return controller;
  }

  void _handleMaterialBannerStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        assert(_materialBanners.isNotEmpty);
        setState(() {
          _materialBanners.removeFirst();
        });
        _updateScaffolds();
        if (_materialBanners.isNotEmpty) {
          _materialBannerController!.forward();
        }
        break;
      case AnimationStatus.completed:
        _updateScaffolds();
        break;
      case AnimationStatus.forward:
        break;
      case AnimationStatus.reverse:
        break;
    }
  }

  /// Removes the current [MaterialBanner] (if any) immediately from registered
  /// [Scaffold]s.
  ///
  /// The removed material banner does not run its normal exit animation. If there are
  /// any queued material banners, they begin their entrance animation immediately.
  void removeCurrentMaterialBanner(
      {MaterialBannerClosedReason reason = MaterialBannerClosedReason.remove}) {
    assert(reason != null);
    if (_materialBanners.isEmpty) return;
    final Completer<MaterialBannerClosedReason> completer =
        _materialBanners.first._completer;
    if (!completer.isCompleted) completer.complete(reason);

    // This will trigger the animation's status callback.
    _materialBannerController!.value = 0.0;
  }

  /// Removes the current [MaterialBanner] by running its normal exit animation.
  ///
  /// The closed completer is called after the animation is complete.
  void hideCurrentMaterialBanner(
      {MaterialBannerClosedReason reason = MaterialBannerClosedReason.hide}) {
    assert(reason != null);
    if (_materialBanners.isEmpty ||
        _materialBannerController!.status == AnimationStatus.dismissed) return;
    final Completer<MaterialBannerClosedReason> completer =
        _materialBanners.first._completer;
    if (_accessibleNavigation!) {
      _materialBannerController!.value = 0.0;
      completer.complete(reason);
    } else {
      _materialBannerController!.reverse().then<void>((void value) {
        assert(mounted);
        if (!completer.isCompleted) completer.complete(reason);
      });
    }
  }

  /// Removes all the materialBanners currently in queue by clearing the queue
  /// and running normal exit animation on the current materialBanner.
  void clearMaterialBanners() {
    if (_materialBanners.isEmpty ||
        _materialBannerController!.status == AnimationStatus.dismissed) return;
    final ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
        currentMaterialBanner = _materialBanners.first;
    _materialBanners.clear();
    _materialBanners.add(currentMaterialBanner);
    hideCurrentMaterialBanner();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    _accessibleNavigation = mediaQuery.accessibleNavigation;

    if (_snackBars.isNotEmpty) {
      final ModalRoute<dynamic>? route = ModalRoute.of(context);
      if (route == null || route.isCurrent) {
        if (_snackBarController!.isCompleted && _snackBarTimer == null) {
          final SnackBar snackBar = _snackBars.first._widget;
          _snackBarTimer = Timer(snackBar.duration, () {
            assert(
              _snackBarController!.status == AnimationStatus.forward ||
                  _snackBarController!.status == AnimationStatus.completed,
            );
            // Look up MediaQuery again in case the setting changed.
            final MediaQueryData mediaQuery = MediaQuery.of(context);
            if (mediaQuery.accessibleNavigation && snackBar.action != null)
              return;
            hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
          });
        }
      }
    }

    return _ScaffoldMessengerScope(
      scaffoldMessengerState: this,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _snackBarController?.dispose();
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    super.dispose();
  }
}

class _ScaffoldMessengerScope extends InheritedWidget {
  const _ScaffoldMessengerScope({
    Key? key,
    required Widget child,
    required ScaffoldMessengerState scaffoldMessengerState,
  })  : _scaffoldMessengerState = scaffoldMessengerState,
        super(key: key, child: child);

  final ScaffoldMessengerState _scaffoldMessengerState;

  @override
  bool updateShouldNotify(_ScaffoldMessengerScope old) =>
      _scaffoldMessengerState != old._scaffoldMessengerState;
}

/// The geometry of the [Scaffold] after all its contents have been laid out
/// except the [FloatingActionButton].
///
/// The [Scaffold] passes this pre-layout geometry to its
/// [FloatingActionButtonLocation], which produces an [Offset] that the
/// [Scaffold] uses to position the [FloatingActionButton].
///
/// For a description of the [Scaffold]'s geometry after it has
/// finished laying out, see the [ScaffoldGeometry].
@immutable
class ScaffoldPrelayoutGeometry {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ScaffoldPrelayoutGeometry({
    required this.bottomSheetSize,
    required this.contentBottom,
    required this.contentTop,
    required this.floatingActionButtonSize,
    required this.minInsets,
    required this.minViewPadding,
    required this.scaffoldSize,
    required this.snackBarSize,
    required this.materialBannerSize,
    required this.textDirection,
  });

  /// The [Size] of [Scaffold.floatingActionButton].
  ///
  /// If [Scaffold.floatingActionButton] is null, this will be [Size.zero].
  final Size floatingActionButtonSize;

  /// The [Size] of the [Scaffold]'s [BottomSheet].
  ///
  /// If the [Scaffold] is not currently showing a [BottomSheet],
  /// this will be [Size.zero].
  final Size bottomSheetSize;

  /// The vertical distance from the Scaffold's origin to the bottom of
  /// [Scaffold.body].
  ///
  /// This is useful in a [FloatingActionButtonLocation] designed to
  /// place the [FloatingActionButton] at the bottom of the screen, while
  /// keeping it above the [BottomSheet], the [Scaffold.bottomNavigationBar],
  /// or the keyboard.
  ///
  /// The [Scaffold.body] is laid out with respect to [minInsets] already. This
  /// means that a [FloatingActionButtonLocation] does not need to factor in
  /// [EdgeInsets.bottom] of [minInsets] when aligning a [FloatingActionButton]
  /// to [contentBottom].
  final double contentBottom;

  /// The vertical distance from the [Scaffold]'s origin to the top of
  /// [Scaffold.body].
  ///
  /// This is useful in a [FloatingActionButtonLocation] designed to
  /// place the [FloatingActionButton] at the top of the screen, while
  /// keeping it below the [Scaffold.appBar].
  ///
  /// The [Scaffold.body] is laid out with respect to [minInsets] already. This
  /// means that a [FloatingActionButtonLocation] does not need to factor in
  /// [EdgeInsets.top] of [minInsets] when aligning a [FloatingActionButton] to
  /// [contentTop].
  final double contentTop;

  /// The minimum padding to inset the [FloatingActionButton] by for it
  /// to remain visible.
  ///
  /// This value is the result of calling [MediaQueryData.padding] in the
  /// [Scaffold]'s [BuildContext],
  /// and is useful for insetting the [FloatingActionButton] to avoid features like
  /// the system status bar or the keyboard.
  ///
  /// If [Scaffold.resizeToAvoidBottomInset] is set to false,
  /// [EdgeInsets.bottom] of [minInsets] will be 0.0.
  final EdgeInsets minInsets;

  /// The minimum padding to inset interactive elements to be within a safe,
  /// un-obscured space.
  ///
  /// This value reflects the [MediaQueryData.viewPadding] of the [Scaffold]'s
  /// [BuildContext] when [Scaffold.resizeToAvoidBottomInset] is false or and
  /// the [MediaQueryData.viewInsets] > 0.0. This helps distinguish between
  /// different types of obstructions on the screen, such as software keyboards
  /// and physical device notches.
  final EdgeInsets minViewPadding;

  /// The [Size] of the whole [Scaffold].
  ///
  /// If the [Size] of the [Scaffold]'s contents is modified by values such as
  /// [Scaffold.resizeToAvoidBottomInset] or the keyboard opening, then the
  /// [scaffoldSize] will not reflect those changes.
  ///
  /// This means that [FloatingActionButtonLocation]s designed to reposition
  /// the [FloatingActionButton] based on events such as the keyboard popping
  /// up should use [minInsets] to make sure that the [FloatingActionButton] is
  /// inset by enough to remain visible.
  ///
  /// See [minInsets] and [MediaQueryData.padding] for more information on the
  /// appropriate insets to apply.
  final Size scaffoldSize;

  /// The [Size] of the [Scaffold]'s [SnackBar].
  ///
  /// If the [Scaffold] is not showing a [SnackBar], this will be [Size.zero].
  final Size snackBarSize;

  /// The [Size] of the [Scaffold]'s [MaterialBanner].
  ///
  /// If the [Scaffold] is not showing a [MaterialBanner], this will be [Size.zero].
  final Size materialBannerSize;

  /// The [TextDirection] of the [Scaffold]'s [BuildContext].
  final TextDirection textDirection;
}

/// A snapshot of a transition between two [FloatingActionButtonLocation]s.
///
/// [ScaffoldState] uses this to seamlessly change transition animations
/// when a running [FloatingActionButtonLocation] transition is interrupted by a new transition.
@immutable
class _TransitionSnapshotFabLocation extends FloatingActionButtonLocation {
  const _TransitionSnapshotFabLocation(
      this.begin, this.end, this.animator, this.progress);

  final FloatingActionButtonLocation begin;
  final FloatingActionButtonLocation end;
  final FloatingActionButtonAnimator animator;
  final double progress;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    return animator.getOffset(
      begin: begin.getOffset(scaffoldGeometry),
      end: end.getOffset(scaffoldGeometry),
      progress: progress,
    );
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, '_TransitionSnapshotFabLocation')}(begin: $begin, end: $end, progress: $progress)';
  }
}

/// Geometry information for [Scaffold] components after layout is finished.
///
/// To get a [ValueNotifier] for the scaffold geometry of a given
/// [BuildContext], use [Scaffold.geometryOf].
///
/// The ScaffoldGeometry is only available during the paint phase, because
/// its value is computed during the animation and layout phases prior to painting.
///
/// For an example of using the [ScaffoldGeometry], see the [BottomAppBar],
/// which uses the [ScaffoldGeometry] to paint a notch around the
/// [FloatingActionButton].
///
/// For information about the [Scaffold]'s geometry that is used while laying
/// out the [FloatingActionButton], see [ScaffoldPrelayoutGeometry].
@immutable
class ScaffoldGeometry {
  /// Create an object that describes the geometry of a [Scaffold].
  const ScaffoldGeometry({
    this.bottomNavigationBarTop,
    this.floatingActionButtonArea,
  });

  /// The distance from the [Scaffold]'s top edge to the top edge of the
  /// rectangle in which the [Scaffold.bottomNavigationBar] bar is laid out.
  ///
  /// Null if [Scaffold.bottomNavigationBar] is null.
  final double? bottomNavigationBarTop;

  /// The [Scaffold.floatingActionButton]'s bounding rectangle.
  ///
  /// This is null when there is no floating action button showing.
  final Rect? floatingActionButtonArea;

  ScaffoldGeometry _scaleFloatingActionButton(double scaleFactor) {
    if (scaleFactor == 1.0) return this;

    if (scaleFactor == 0.0) {
      return ScaffoldGeometry(
        bottomNavigationBarTop: bottomNavigationBarTop,
      );
    }

    final Rect scaledButton = Rect.lerp(
      floatingActionButtonArea!.center & Size.zero,
      floatingActionButtonArea,
      scaleFactor,
    )!;
    return copyWith(floatingActionButtonArea: scaledButton);
  }

  /// Creates a copy of this [ScaffoldGeometry] but with the given fields replaced with
  /// the new values.
  ScaffoldGeometry copyWith({
    double? bottomNavigationBarTop,
    Rect? floatingActionButtonArea,
  }) {
    return ScaffoldGeometry(
      bottomNavigationBarTop:
          bottomNavigationBarTop ?? this.bottomNavigationBarTop,
      floatingActionButtonArea:
          floatingActionButtonArea ?? this.floatingActionButtonArea,
    );
  }
}

class _ScaffoldGeometryNotifier extends ChangeNotifier
    implements ValueListenable<ScaffoldGeometry> {
  _ScaffoldGeometryNotifier(this.geometry, this.context)
      : assert(context != null);

  final BuildContext context;
  double? floatingActionButtonScale;
  ScaffoldGeometry geometry;

  @override
  ScaffoldGeometry get value {
    assert(() {
      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject == null || !renderObject.owner!.debugDoingPaint)
        throw FlutterError(
          'Scaffold.geometryOf() must only be accessed during the paint phase.\n'
          'The ScaffoldGeometry is only available during the paint phase, because '
          'its value is computed during the animation and layout phases prior to painting.',
        );
      return true;
    }());
    return geometry._scaleFloatingActionButton(floatingActionButtonScale!);
  }

  void _updateWith({
    double? bottomNavigationBarTop,
    Rect? floatingActionButtonArea,
    double? floatingActionButtonScale,
  }) {
    this.floatingActionButtonScale =
        floatingActionButtonScale ?? this.floatingActionButtonScale;
    geometry = geometry.copyWith(
      bottomNavigationBarTop: bottomNavigationBarTop,
      floatingActionButtonArea: floatingActionButtonArea,
    );
    notifyListeners();
  }
}

// Used to communicate the height of the Scaffold's bottomNavigationBar and
// persistentFooterButtons to the LayoutBuilder which builds the Scaffold's body.
//
// Scaffold expects a _BodyBoxConstraints to be passed to the _BodyBuilder
// widget's LayoutBuilder, see _ScaffoldLayout.performLayout(). The BoxConstraints
// methods that construct new BoxConstraints objects, like copyWith() have not
// been overridden here because we expect the _BodyBoxConstraintsObject to be
// passed along unmodified to the LayoutBuilder. If that changes in the future
// then _BodyBuilder will assert.
class _BodyBoxConstraints extends BoxConstraints {
  const _BodyBoxConstraints({
    double minWidth = 0.0,
    double maxWidth = double.infinity,
    double minHeight = 0.0,
    double maxHeight = double.infinity,
    required this.bottomWidgetsHeight,
    required this.appBarHeight,
  })  : assert(bottomWidgetsHeight != null),
        assert(bottomWidgetsHeight >= 0),
        assert(appBarHeight != null),
        assert(appBarHeight >= 0),
        super(
            minWidth: minWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            maxHeight: maxHeight);

  final double bottomWidgetsHeight;
  final double appBarHeight;

  // RenderObject.layout() will only short-circuit its call to its performLayout
  // method if the new layout constraints are not == to the current constraints.
  // If the height of the bottom widgets has changed, even though the constraints'
  // min and max values have not, we still want performLayout to happen.
  @override
  bool operator ==(Object other) {
    if (super != other) return false;
    return other is _BodyBoxConstraints &&
        other.bottomWidgetsHeight == bottomWidgetsHeight &&
        other.appBarHeight == appBarHeight;
  }

  @override
  int get hashCode {
    return hashValues(super.hashCode, bottomWidgetsHeight, appBarHeight);
  }
}

// Used when Scaffold.extendBody is true to wrap the scaffold's body in a MediaQuery
// whose padding accounts for the height of the bottomNavigationBar and/or the
// persistentFooterButtons.
//
// The bottom widgets' height is passed along via the _BodyBoxConstraints parameter.
// The constraints parameter is constructed in_ScaffoldLayout.performLayout().
class _BodyBuilder extends StatelessWidget {
  const _BodyBuilder({
    Key? key,
    required this.extendBody,
    required this.extendBodyBehindAppBar,
    required this.body,
  })  : assert(extendBody != null),
        assert(extendBodyBehindAppBar != null),
        assert(body != null),
        super(key: key);

  final Widget body;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    if (!extendBody && !extendBodyBehindAppBar) return body;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final _BodyBoxConstraints bodyConstraints =
            constraints as _BodyBoxConstraints;
        final MediaQueryData metrics = MediaQuery.of(context);

        final double bottom = extendBody
            ? math.max(
                metrics.padding.bottom, bodyConstraints.bottomWidgetsHeight)
            : metrics.padding.bottom;

        final double top = extendBodyBehindAppBar
            ? math.max(metrics.padding.top, bodyConstraints.appBarHeight)
            : metrics.padding.top;

        return MediaQuery(
          data: metrics.copyWith(
            padding: metrics.padding.copyWith(
              top: top,
              bottom: bottom,
            ),
          ),
          child: body,
        );
      },
    );
  }
}

class _ScaffoldLayout extends MultiChildLayoutDelegate {
  _ScaffoldLayout({
    required this.minInsets,
    required this.minViewPadding,
    required this.textDirection,
    required this.geometryNotifier,
    // for floating action button
    required this.previousFloatingActionButtonLocation,
    required this.currentFloatingActionButtonLocation,
    required this.floatingActionButtonMoveAnimationProgress,
    required this.floatingActionButtonMotionAnimator,
    required this.isSnackBarFloating,
    required this.snackBarWidth,
    required this.extendBody,
    required this.extendBodyBehindAppBar,
  })  : assert(minInsets != null),
        assert(textDirection != null),
        assert(geometryNotifier != null),
        assert(previousFloatingActionButtonLocation != null),
        assert(currentFloatingActionButtonLocation != null),
        assert(extendBody != null),
        assert(extendBodyBehindAppBar != null);

  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final EdgeInsets minInsets;
  final EdgeInsets minViewPadding;
  final TextDirection textDirection;
  final _ScaffoldGeometryNotifier geometryNotifier;

  final FloatingActionButtonLocation previousFloatingActionButtonLocation;
  final FloatingActionButtonLocation currentFloatingActionButtonLocation;
  final double floatingActionButtonMoveAnimationProgress;
  final FloatingActionButtonAnimator floatingActionButtonMotionAnimator;

  final bool isSnackBarFloating;
  final double? snackBarWidth;

  @override
  void performLayout(Size size) {
    final BoxConstraints looseConstraints = BoxConstraints.loose(size);

    // This part of the layout has the same effect as putting the app bar and
    // body in a column and making the body flexible. What's different is that
    // in this case the app bar appears _after_ the body in the stacking order,
    // so the app bar's shadow is drawn on top of the body.

    final BoxConstraints fullWidthConstraints =
        looseConstraints.tighten(width: size.width);
    final double bottom = size.height;
    double contentTop = 0.0;
    double bottomWidgetsHeight = 0.0;
    double appBarHeight = 0.0;

    if (hasChild(_ScaffoldSlot.appBar)) {
      appBarHeight =
          layoutChild(_ScaffoldSlot.appBar, fullWidthConstraints).height;
      contentTop = extendBodyBehindAppBar ? 0.0 : appBarHeight;
      positionChild(_ScaffoldSlot.appBar, Offset.zero);
    }

    double? bottomNavigationBarTop;
    if (hasChild(_ScaffoldSlot.bottomNavigationBar)) {
      final double bottomNavigationBarHeight =
          layoutChild(_ScaffoldSlot.bottomNavigationBar, fullWidthConstraints)
              .height;
      bottomWidgetsHeight += bottomNavigationBarHeight;
      bottomNavigationBarTop = math.max(0.0, bottom - bottomWidgetsHeight);
      positionChild(_ScaffoldSlot.bottomNavigationBar,
          Offset(0.0, bottomNavigationBarTop));
    }

    if (hasChild(_ScaffoldSlot.persistentFooter)) {
      final BoxConstraints footerConstraints = BoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: math.max(0.0, bottom - bottomWidgetsHeight - contentTop),
      );
      final double persistentFooterHeight =
          layoutChild(_ScaffoldSlot.persistentFooter, footerConstraints).height;
      bottomWidgetsHeight += persistentFooterHeight;
      positionChild(_ScaffoldSlot.persistentFooter,
          Offset(0.0, math.max(0.0, bottom - bottomWidgetsHeight)));
    }

    // Set the content bottom to account for the greater of the height of any
    // bottom-anchored material widgets or of the keyboard or other
    // bottom-anchored system UI.
    final double contentBottom =
        math.max(0.0, bottom - math.max(minInsets.bottom, bottomWidgetsHeight));

    if (hasChild(_ScaffoldSlot.body)) {
      double bodyMaxHeight = math.max(0.0, contentBottom - contentTop);

      if (extendBody) {
        bodyMaxHeight += bottomWidgetsHeight;
        bodyMaxHeight =
            bodyMaxHeight.clamp(0.0, looseConstraints.maxHeight - contentTop);
        assert(bodyMaxHeight <=
            math.max(0.0, looseConstraints.maxHeight - contentTop));
      }

      final BoxConstraints bodyConstraints = _BodyBoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: bodyMaxHeight,
        bottomWidgetsHeight: extendBody ? bottomWidgetsHeight : 0.0,
        appBarHeight: appBarHeight,
      );
      layoutChild(_ScaffoldSlot.body, bodyConstraints);
      positionChild(_ScaffoldSlot.body, Offset(0.0, contentTop));
    }

    // The BottomSheet and the SnackBar are anchored to the bottom of the parent,
    // they're as wide as the parent and are given their intrinsic height. The
    // only difference is that SnackBar appears on the top side of the
    // BottomNavigationBar while the BottomSheet is stacked on top of it.
    //
    // If all three elements are present then either the center of the FAB straddles
    // the top edge of the BottomSheet or the bottom of the FAB is
    // kFloatingActionButtonMargin above the SnackBar, whichever puts the FAB
    // the farthest above the bottom of the parent. If only the FAB is has a
    // non-zero height then it's inset from the parent's right and bottom edges
    // by kFloatingActionButtonMargin.

    Size bottomSheetSize = Size.zero;
    Size snackBarSize = Size.zero;
    if (hasChild(_ScaffoldSlot.bodyScrim)) {
      final BoxConstraints bottomSheetScrimConstraints = BoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: contentBottom,
      );
      layoutChild(_ScaffoldSlot.bodyScrim, bottomSheetScrimConstraints);
      positionChild(_ScaffoldSlot.bodyScrim, Offset.zero);
    }

    // Set the size of the SnackBar early if the behavior is fixed so
    // the FAB can be positioned correctly.
    if (hasChild(_ScaffoldSlot.snackBar) && !isSnackBarFloating) {
      snackBarSize = layoutChild(_ScaffoldSlot.snackBar, fullWidthConstraints);
    }

    Size materialBannerSize = Size.zero;
    if (hasChild(_ScaffoldSlot.materialBanner)) {
      materialBannerSize =
          layoutChild(_ScaffoldSlot.materialBanner, fullWidthConstraints);
    }

    if (hasChild(_ScaffoldSlot.bottomSheet)) {
      final BoxConstraints bottomSheetConstraints = BoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: math.max(0.0, contentBottom - contentTop),
      );
      bottomSheetSize =
          layoutChild(_ScaffoldSlot.bottomSheet, bottomSheetConstraints);
      positionChild(
          _ScaffoldSlot.bottomSheet,
          Offset((size.width - bottomSheetSize.width) / 2.0,
              contentBottom - bottomSheetSize.height));
    }

    late Rect floatingActionButtonRect;
    if (hasChild(_ScaffoldSlot.floatingActionButton)) {
      final Size fabSize =
          layoutChild(_ScaffoldSlot.floatingActionButton, looseConstraints);

      // To account for the FAB position being changed, we'll animate between
      // the old and new positions.
      final ScaffoldPrelayoutGeometry currentGeometry =
          ScaffoldPrelayoutGeometry(
        bottomSheetSize: bottomSheetSize,
        contentBottom: contentBottom,

        /// [appBarHeight] should be used instead of [contentTop] because
        /// ScaffoldPrelayoutGeometry.contentTop must not be affected by [extendBodyBehindAppBar].
        contentTop: appBarHeight,
        floatingActionButtonSize: fabSize,
        minInsets: minInsets,
        scaffoldSize: size,
        snackBarSize: snackBarSize,
        materialBannerSize: materialBannerSize,
        textDirection: textDirection,
        minViewPadding: minViewPadding,
      );
      final Offset currentFabOffset =
          currentFloatingActionButtonLocation.getOffset(currentGeometry);
      final Offset previousFabOffset =
          previousFloatingActionButtonLocation.getOffset(currentGeometry);
      final Offset fabOffset = floatingActionButtonMotionAnimator.getOffset(
        begin: previousFabOffset,
        end: currentFabOffset,
        progress: floatingActionButtonMoveAnimationProgress,
      );
      positionChild(_ScaffoldSlot.floatingActionButton, fabOffset);
      floatingActionButtonRect = fabOffset & fabSize;
    }

    if (hasChild(_ScaffoldSlot.snackBar)) {
      final bool hasCustomWidth =
          snackBarWidth != null && snackBarWidth! < size.width;
      if (snackBarSize == Size.zero) {
        snackBarSize = layoutChild(
          _ScaffoldSlot.snackBar,
          hasCustomWidth ? looseConstraints : fullWidthConstraints,
        );
      }

      final double snackBarYOffsetBase;
      if (floatingActionButtonRect.size != Size.zero && isSnackBarFloating) {
        snackBarYOffsetBase = floatingActionButtonRect.top;
      } else {
        // SnackBarBehavior.fixed applies a SafeArea automatically.
        // SnackBarBehavior.floating does not since the positioning is affected
        // if there is a FloatingActionButton (see condition above). If there is
        // no FAB, make sure we account for safe space when the SnackBar is
        // floating.
        final double safeYOffsetBase = size.height - minViewPadding.bottom;
        snackBarYOffsetBase = isSnackBarFloating
            ? math.min(contentBottom, safeYOffsetBase)
            : contentBottom;
      }

      final double xOffset =
          hasCustomWidth ? (size.width - snackBarWidth!) / 2 : 0.0;
      positionChild(_ScaffoldSlot.snackBar,
          Offset(xOffset, snackBarYOffsetBase - snackBarSize.height));
    }

    if (hasChild(_ScaffoldSlot.materialBanner)) {
      if (materialBannerSize == Size.zero) {
        materialBannerSize = layoutChild(
          _ScaffoldSlot.materialBanner,
          fullWidthConstraints,
        );
      }

      positionChild(_ScaffoldSlot.materialBanner, Offset(0.0, appBarHeight));
    }

    if (hasChild(_ScaffoldSlot.statusBar)) {
      layoutChild(_ScaffoldSlot.statusBar,
          fullWidthConstraints.tighten(height: minInsets.top));
      positionChild(_ScaffoldSlot.statusBar, Offset.zero);
    }

    if (hasChild(_ScaffoldSlot.drawer)) {
      layoutChild(_ScaffoldSlot.drawer, BoxConstraints.tight(size));
      positionChild(_ScaffoldSlot.drawer, Offset.zero);
    }

    if (hasChild(_ScaffoldSlot.endDrawer)) {
      layoutChild(_ScaffoldSlot.endDrawer, BoxConstraints.tight(size));
      positionChild(_ScaffoldSlot.endDrawer, Offset.zero);
    }

    geometryNotifier._updateWith(
      bottomNavigationBarTop: bottomNavigationBarTop,
      floatingActionButtonArea: floatingActionButtonRect,
    );
  }

  @override
  bool shouldRelayout(_ScaffoldLayout oldDelegate) {
    return oldDelegate.minInsets != minInsets ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.floatingActionButtonMoveAnimationProgress !=
            floatingActionButtonMoveAnimationProgress ||
        oldDelegate.previousFloatingActionButtonLocation !=
            previousFloatingActionButtonLocation ||
        oldDelegate.currentFloatingActionButtonLocation !=
            currentFloatingActionButtonLocation ||
        oldDelegate.extendBody != extendBody ||
        oldDelegate.extendBodyBehindAppBar != extendBodyBehindAppBar;
  }
}

/// Handler for scale and rotation animations in the [FloatingActionButton].
///
/// Currently, there are two types of [FloatingActionButton] animations:
///
/// * Entrance/Exit animations, which this widget triggers
///   when the [FloatingActionButton] is added, updated, or removed.
/// * Motion animations, which are triggered by the [Scaffold]
///   when its [FloatingActionButtonLocation] is updated.
class _FloatingActionButtonTransition extends StatefulWidget {
  const _FloatingActionButtonTransition({
    Key? key,
    required this.child,
    required this.fabMoveAnimation,
    required this.fabMotionAnimator,
    required this.geometryNotifier,
    required this.currentController,
  })  : assert(fabMoveAnimation != null),
        assert(fabMotionAnimator != null),
        assert(currentController != null),
        super(key: key);

  final Widget? child;
  final Animation<double> fabMoveAnimation;
  final FloatingActionButtonAnimator fabMotionAnimator;
  final _ScaffoldGeometryNotifier geometryNotifier;

  /// Controls the current child widget.child as it exits.
  final AnimationController currentController;

  @override
  _FloatingActionButtonTransitionState createState() =>
      _FloatingActionButtonTransitionState();
}

class _FloatingActionButtonTransitionState
    extends State<_FloatingActionButtonTransition>
    with TickerProviderStateMixin {
  // The animations applied to the Floating Action Button when it is entering or exiting.
  // Controls the previous widget.child as it exits.
  late AnimationController _previousController;
  late Animation<double> _previousScaleAnimation;
  late Animation<double> _previousRotationAnimation;
  // The animations to run, considering the widget's fabMoveAnimation and the current/previous entrance/exit animations.
  late Animation<double> _currentScaleAnimation;
  late Animation<double> _extendedCurrentScaleAnimation;
  late Animation<double> _currentRotationAnimation;
  Widget? _previousChild;

  @override
  void initState() {
    super.initState();

    _previousController = AnimationController(
      duration: kFloatingActionButtonSegue,
      vsync: this,
    )..addStatusListener(_handlePreviousAnimationStatusChanged);
    _updateAnimations();

    if (widget.child != null) {
      // If we start out with a child, have the child appear fully visible instead
      // of animating in.
      widget.currentController.value = 1.0;
    } else {
      // If we start without a child we update the geometry object with a
      // floating action button scale of 0, as it is not showing on the screen.
      _updateGeometryScale(0.0);
    }
  }

  @override
  void dispose() {
    _previousController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FloatingActionButtonTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool oldChildIsNull = oldWidget.child == null;
    final bool newChildIsNull = widget.child == null;
    if (oldChildIsNull == newChildIsNull &&
        oldWidget.child?.key == widget.child?.key) return;
    if (oldWidget.fabMotionAnimator != widget.fabMotionAnimator ||
        oldWidget.fabMoveAnimation != widget.fabMoveAnimation) {
      // Get the right scale and rotation animations to use for this widget.
      _updateAnimations();
    }
    if (_previousController.status == AnimationStatus.dismissed) {
      final double currentValue = widget.currentController.value;
      if (currentValue == 0.0 || oldWidget.child == null) {
        // The current child hasn't started its entrance animation yet. We can
        // just skip directly to the new child's entrance.
        _previousChild = null;
        if (widget.child != null) widget.currentController.forward();
      } else {
        // Otherwise, we need to copy the state from the current controller to
        // the previous controller and run an exit animation for the previous
        // widget before running the entrance animation for the new child.
        _previousChild = oldWidget.child;
        _previousController
          ..value = currentValue
          ..reverse();
        widget.currentController.value = 0.0;
      }
    }
  }

  static final Animatable<double> _entranceTurnTween = Tween<double>(
    begin: 1.0 - kFloatingActionButtonTurnInterval,
    end: 1.0,
  ).chain(CurveTween(curve: Curves.easeIn));

  void _updateAnimations() {
    // Get the animations for exit and entrance.
    final CurvedAnimation previousExitScaleAnimation = CurvedAnimation(
      parent: _previousController,
      curve: Curves.easeIn,
    );
    final Animation<double> previousExitRotationAnimation =
        Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _previousController,
        curve: Curves.easeIn,
      ),
    );

    final CurvedAnimation currentEntranceScaleAnimation = CurvedAnimation(
      parent: widget.currentController,
      curve: Curves.easeIn,
    );
    final Animation<double> currentEntranceRotationAnimation =
        widget.currentController.drive(_entranceTurnTween);

    // Get the animations for when the FAB is moving.
    final Animation<double> moveScaleAnimation = widget.fabMotionAnimator
        .getScaleAnimation(parent: widget.fabMoveAnimation);
    final Animation<double> moveRotationAnimation = widget.fabMotionAnimator
        .getRotationAnimation(parent: widget.fabMoveAnimation);

    // Aggregate the animations.
    _previousScaleAnimation =
        AnimationMin<double>(moveScaleAnimation, previousExitScaleAnimation);
    _currentScaleAnimation =
        AnimationMin<double>(moveScaleAnimation, currentEntranceScaleAnimation);
    _extendedCurrentScaleAnimation = _currentScaleAnimation
        .drive(CurveTween(curve: const Interval(0.0, 0.1)));

    _previousRotationAnimation = TrainHoppingAnimation(
        previousExitRotationAnimation, moveRotationAnimation);
    _currentRotationAnimation = TrainHoppingAnimation(
        currentEntranceRotationAnimation, moveRotationAnimation);

    _currentScaleAnimation.addListener(_onProgressChanged);
    _previousScaleAnimation.addListener(_onProgressChanged);
  }

  void _handlePreviousAnimationStatusChanged(AnimationStatus status) {
    setState(() {
      if (status == AnimationStatus.dismissed) {
        assert(widget.currentController.status == AnimationStatus.dismissed);
        if (widget.child != null) widget.currentController.forward();
      }
    });
  }

  bool _isExtendedFloatingActionButton(Widget? widget) {
    return widget is FloatingActionButton && widget.isExtended;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: <Widget>[
        if (_previousController.status != AnimationStatus.dismissed)
          if (_isExtendedFloatingActionButton(_previousChild))
            FadeTransition(
              opacity: _previousScaleAnimation,
              child: _previousChild,
            )
          else
            ScaleTransition(
              scale: _previousScaleAnimation,
              child: RotationTransition(
                turns: _previousRotationAnimation,
                child: _previousChild,
              ),
            ),
        if (_isExtendedFloatingActionButton(widget.child))
          ScaleTransition(
            scale: _extendedCurrentScaleAnimation,
            child: FadeTransition(
              opacity: _currentScaleAnimation,
              child: widget.child,
            ),
          )
        else
          ScaleTransition(
            scale: _currentScaleAnimation,
            child: RotationTransition(
              turns: _currentRotationAnimation,
              child: widget.child,
            ),
          ),
      ],
    );
  }

  void _onProgressChanged() {
    _updateGeometryScale(
        math.max(_previousScaleAnimation.value, _currentScaleAnimation.value));
  }

  void _updateGeometryScale(double scale) {
    widget.geometryNotifier._updateWith(
      floatingActionButtonScale: scale,
    );
  }
}

/// Implements the basic material design visual layout structure.
///
/// This class provides APIs for showing drawers and bottom sheets.
///
/// To display a persistent bottom sheet, obtain the
/// [ScaffoldState] for the current [BuildContext] via [Scaffold.of] and use the
/// [ScaffoldState.showBottomSheet] function.
///
/// {@tool dartpad --template=stateful_widget_material}
/// This example shows a [Scaffold] with a [body] and [FloatingActionButton].
/// The [body] is a [Text] placed in a [Center] in order to center the text
/// within the [Scaffold]. The [FloatingActionButton] is connected to a
/// callback that increments a counter.
///
/// ![The Scaffold has a white background with a blue AppBar at the top. A blue FloatingActionButton is positioned at the bottom right corner of the Scaffold.](https://flutter.github.io/assets-for-api-docs/assets/material/scaffold.png)
///
/// ```dart
/// int _count = 0;
///
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: const Text('Sample Code'),
///     ),
///     body: Center(
///       child: Text('You have pressed the button $_count times.')
///     ),
///     floatingActionButton: FloatingActionButton(
///       onPressed: () => setState(() => _count++),
///       tooltip: 'Increment Counter',
///       child: Icon(Icons.add),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateful_widget_material}
/// This example shows a [Scaffold] with a blueGrey [backgroundColor], [body]
/// and [FloatingActionButton]. The [body] is a [Text] placed in a [Center] in
/// order to center the text within the [Scaffold]. The [FloatingActionButton]
/// is connected to a callback that increments a counter.
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/material/scaffold_background_color.png)
///
/// ```dart
/// int _count = 0;
///
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: const Text('Sample Code'),
///     ),
///     body: Center(
///       child: Text('You have pressed the button $_count times.')
///     ),
///     backgroundColor: Colors.blueGrey.shade200,
///     floatingActionButton: FloatingActionButton(
///       onPressed: () => setState(() => _count++),
///       tooltip: 'Increment Counter',
///       child: Icon(Icons.add),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateful_widget_material}
/// This example shows a [Scaffold] with an [AppBar], a [BottomAppBar] and a
/// [FloatingActionButton]. The [body] is a [Text] placed in a [Center] in order
/// to center the text within the [Scaffold]. The [FloatingActionButton] is
/// centered and docked within the [BottomAppBar] using
/// [FloatingActionButtonLocation.centerDocked]. The [FloatingActionButton] is
/// connected to a callback that increments a counter.
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/material/scaffold_bottom_app_bar.png)
///
/// ```dart
/// int _count = 0;
///
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: const Text('Sample Code'),
///     ),
///     body: Center(
///       child: Text('You have pressed the button $_count times.'),
///     ),
///     bottomNavigationBar: BottomAppBar(
///       shape: const CircularNotchedRectangle(),
///       child: Container(height: 50.0),
///     ),
///     floatingActionButton: FloatingActionButton(
///       onPressed: () => setState(() {
///         _count++;
///       }),
///       tooltip: 'Increment Counter',
///       child: Icon(Icons.add),
///     ),
///     floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
///   );
/// }
/// ```
/// {@end-tool}
///
/// ## Scaffold layout, the keyboard, and display "notches"
///
/// The scaffold will expand to fill the available space. That usually
/// means that it will occupy its entire window or device screen. When
/// the device's keyboard appears the Scaffold's ancestor [MediaQuery]
/// widget's [MediaQueryData.viewInsets] changes and the Scaffold will
/// be rebuilt. By default the scaffold's [body] is resized to make
/// room for the keyboard. To prevent the resize set
/// [resizeToAvoidBottomInset] to false. In either case the focused
/// widget will be scrolled into view if it's within a scrollable
/// container.
///
/// The [MediaQueryData.padding] value defines areas that might
/// not be completely visible, like the display "notch" on the iPhone
/// X. The scaffold's [body] is not inset by this padding value
/// although an [appBar] or [bottomNavigationBar] will typically
/// cause the body to avoid the padding. The [SafeArea]
/// widget can be used within the scaffold's body to avoid areas
/// like display notches.
///
/// ## Troubleshooting
///
/// ### Nested Scaffolds
///
/// The Scaffold is designed to be a top level container for
/// a [MaterialApp]. This means that adding a Scaffold
/// to each route on a Material app will provide the app with
/// Material's basic visual layout structure.
///
/// It is typically not necessary to nest Scaffolds. For example, in a
/// tabbed UI, where the [bottomNavigationBar] is a [TabBar]
/// and the body is a [TabBarView], you might be tempted to make each tab bar
/// view a scaffold with a differently titled AppBar. Rather, it would be
/// better to add a listener to the [TabController] that updates the
/// AppBar
///
/// {@tool snippet}
/// Add a listener to the app's tab controller so that the [AppBar] title of the
/// app's one and only scaffold is reset each time a new tab is selected.
///
/// ```dart
/// TabController(vsync: tickerProvider, length: tabCount)..addListener(() {
///   if (!tabController.indexIsChanging) {
///     setState(() {
///       // Rebuild the enclosing scaffold with a new AppBar title
///       appBarTitle = 'Tab ${tabController.index}';
///     });
///   }
/// })
/// ```
/// {@end-tool}
///
/// Although there are some use cases, like a presentation app that
/// shows embedded flutter content, where nested scaffolds are
/// appropriate, it's best to avoid nesting scaffolds.
///
/// See also:
///
///  * [AppBar], which is a horizontal bar typically shown at the top of an app
///    using the [appBar] property.
///  * [BottomAppBar], which is a horizontal bar typically shown at the bottom
///    of an app using the [bottomNavigationBar] property.
///  * [FloatingActionButton], which is a circular button typically shown in the
///    bottom right corner of the app using the [floatingActionButton] property.
///  * [Drawer], which is a vertical panel that is typically displayed to the
///    left of the body (and often hidden on phones) using the [drawer]
///    property.
///  * [BottomNavigationBar], which is a horizontal array of buttons typically
///    shown along the bottom of the app using the [bottomNavigationBar]
///    property.
///  * [BottomSheet], which is an overlay typically shown near the bottom of the
///    app. A bottom sheet can either be persistent, in which case it is shown
///    using the [ScaffoldState.showBottomSheet] method, or modal, in which case
///    it is shown using the [showModalBottomSheet] function.
///  * [ScaffoldState], which is the state associated with this widget.
///  * <https://material.io/design/layout/responsive-layout-grid.html>
///  * Cookbook: [Add a Drawer to a screen](https://flutter.dev/docs/cookbook/design/drawer)
class Scaffold extends StatelessWidget {
  /// Creates a visual scaffold for material design widgets.
  const Scaffold({
    Key? key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
  })  : assert(primary != null),
        assert(extendBody != null),
        assert(extendBodyBehindAppBar != null),
        assert(drawerDragStartBehavior != null),
        super(key: key);

  /// If true, and [bottomNavigationBar] or [persistentFooterButtons]
  /// is specified, then the [body] extends to the bottom of the Scaffold,
  /// instead of only extending to the top of the [bottomNavigationBar]
  /// or the [persistentFooterButtons].
  ///
  /// If true, a [MediaQuery] widget whose bottom padding matches the height
  /// of the [bottomNavigationBar] will be added above the scaffold's [body].
  ///
  /// This property is often useful when the [bottomNavigationBar] has
  /// a non-rectangular shape, like [CircularNotchedRectangle], which
  /// adds a [FloatingActionButton] sized notch to the top edge of the bar.
  /// In this case specifying `extendBody: true` ensures that scaffold's
  /// body will be visible through the bottom navigation bar's notch.
  ///
  /// See also:
  ///
  ///  * [extendBodyBehindAppBar], which extends the height of the body
  ///    to the top of the scaffold.
  final bool extendBody;

  /// If true, and an [appBar] is specified, then the height of the [body] is
  /// extended to include the height of the app bar and the top of the body
  /// is aligned with the top of the app bar.
  ///
  /// This is useful if the app bar's [AppBar.backgroundColor] is not
  /// completely opaque.
  ///
  /// This property is false by default. It must not be null.
  ///
  /// See also:
  ///
  ///  * [extendBody], which extends the height of the body to the bottom
  ///    of the scaffold.
  final bool extendBodyBehindAppBar;

  /// An app bar to display at the top of the scaffold.
  final PreferredSizeWidget? appBar;

  /// The primary content of the scaffold.
  ///
  /// Displayed below the [appBar], above the bottom of the ambient
  /// [MediaQuery]'s [MediaQueryData.viewInsets], and behind the
  /// [floatingActionButton] and [drawer]. If [resizeToAvoidBottomInset] is
  /// false then the body is not resized when the onscreen keyboard appears,
  /// i.e. it is not inset by `viewInsets.bottom`.
  ///
  /// The widget in the body of the scaffold is positioned at the top-left of
  /// the available space between the app bar and the bottom of the scaffold. To
  /// center this widget instead, consider putting it in a [Center] widget and
  /// having that be the body. To expand this widget instead, consider
  /// putting it in a [SizedBox.expand].
  ///
  /// If you have a column of widgets that should normally fit on the screen,
  /// but may overflow and would in such cases need to scroll, consider using a
  /// [ListView] as the body of the scaffold. This is also a good choice for
  /// the case where your body is a scrollable list.
  final Widget? body;

  /// A button displayed floating above [body], in the bottom right corner.
  ///
  /// Typically a [FloatingActionButton].
  final Widget? floatingActionButton;

  /// Responsible for determining where the [floatingActionButton] should go.
  ///
  /// If null, the [ScaffoldState] will use the default location, [FloatingActionButtonLocation.endFloat].
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Animator to move the [floatingActionButton] to a new [floatingActionButtonLocation].
  ///
  /// If null, the [ScaffoldState] will use the default animator, [FloatingActionButtonAnimator.scaling].
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;

  /// A set of buttons that are displayed at the bottom of the scaffold.
  ///
  /// Typically this is a list of [TextButton] widgets. These buttons are
  /// persistently visible, even if the [body] of the scaffold scrolls.
  ///
  /// These widgets will be wrapped in an [OverflowBar].
  ///
  /// The [persistentFooterButtons] are rendered above the
  /// [bottomNavigationBar] but below the [body].
  final List<Widget>? persistentFooterButtons;

  /// A panel displayed to the side of the [body], often hidden on mobile
  /// devices. Swipes in from either left-to-right ([TextDirection.ltr]) or
  /// right-to-left ([TextDirection.rtl])
  ///
  /// Typically a [Drawer].
  ///
  /// To open the drawer, use the [ScaffoldState.openDrawer] function.
  ///
  /// To close the drawer, use [Navigator.pop].
  ///
  /// {@tool dartpad --template=stateful_widget_material}
  /// To disable the drawer edge swipe, set the
  /// [Scaffold.drawerEnableOpenDragGesture] to false. Then, use
  /// [ScaffoldState.openDrawer] to open the drawer and [Navigator.pop] to close
  /// it.
  ///
  /// ```dart
  /// final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ///
  /// void _openDrawer() {
  ///   _scaffoldKey.currentState!.openDrawer();
  /// }
  ///
  /// void _closeDrawer() {
  ///   Navigator.of(context).pop();
  /// }
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return Scaffold(
  ///     key: _scaffoldKey,
  ///     appBar: AppBar(title: const Text('Drawer Demo')),
  ///     body: Center(
  ///       child: ElevatedButton(
  ///         onPressed: _openDrawer,
  ///         child: const Text('Open Drawer'),
  ///       ),
  ///     ),
  ///     drawer: Drawer(
  ///       child: Center(
  ///         child: Column(
  ///           mainAxisAlignment: MainAxisAlignment.center,
  ///           children: <Widget>[
  ///             const Text('This is the Drawer'),
  ///             ElevatedButton(
  ///               onPressed: _closeDrawer,
  ///               child: const Text('Close Drawer'),
  ///             ),
  ///           ],
  ///         ),
  ///       ),
  ///     ),
  ///     // Disable opening the drawer with a swipe gesture.
  ///     drawerEnableOpenDragGesture: false,
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final Widget? drawer;

  /// A panel displayed to the side of the [body], often hidden on mobile
  /// devices. Swipes in from right-to-left ([TextDirection.ltr]) or
  /// left-to-right ([TextDirection.rtl])
  ///
  /// Typically a [Drawer].
  ///
  /// To open the drawer, use the [ScaffoldState.openEndDrawer] function.
  ///
  /// To close the drawer, use [Navigator.pop].
  ///
  /// {@tool dartpad --template=stateful_widget_material}
  /// To disable the drawer edge swipe, set the
  /// [Scaffold.endDrawerEnableOpenDragGesture] to false. Then, use
  /// [ScaffoldState.openEndDrawer] to open the drawer and [Navigator.pop] to
  /// close it.
  ///
  /// ```dart
  /// final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ///
  /// void _openEndDrawer() {
  ///   _scaffoldKey.currentState!.openEndDrawer();
  /// }
  ///
  /// void _closeEndDrawer() {
  ///   Navigator.of(context).pop();
  /// }
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return Scaffold(
  ///     key: _scaffoldKey,
  ///     appBar: AppBar(title: const Text('Drawer Demo')),
  ///     body: Center(
  ///       child: ElevatedButton(
  ///         onPressed: _openEndDrawer,
  ///         child: const Text('Open End Drawer'),
  ///       ),
  ///     ),
  ///     endDrawer: Drawer(
  ///       child: Center(
  ///         child: Column(
  ///           mainAxisAlignment: MainAxisAlignment.center,
  ///           children: <Widget>[
  ///             const Text('This is the Drawer'),
  ///             ElevatedButton(
  ///               onPressed: _closeEndDrawer,
  ///               child: const Text('Close Drawer'),
  ///             ),
  ///           ],
  ///         ),
  ///       ),
  ///     ),
  ///     // Disable opening the end drawer with a swipe gesture.
  ///     endDrawerEnableOpenDragGesture: false,
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final Widget? endDrawer;

  /// The color to use for the scrim that obscures primary content while a drawer is open.
  ///
  /// By default, the color is [Colors.black54]
  final Color? drawerScrimColor;

  /// The color of the [Material] widget that underlies the entire Scaffold.
  ///
  /// The theme's [ThemeData.scaffoldBackgroundColor] by default.
  final Color? backgroundColor;

  /// A bottom navigation bar to display at the bottom of the scaffold.
  ///
  /// Snack bars slide from underneath the bottom navigation bar while bottom
  /// sheets are stacked on top.
  ///
  /// The [bottomNavigationBar] is rendered below the [persistentFooterButtons]
  /// and the [body].
  final Widget? bottomNavigationBar;

  /// The persistent bottom sheet to display.
  ///
  /// A persistent bottom sheet shows information that supplements the primary
  /// content of the app. A persistent bottom sheet remains visible even when
  /// the user interacts with other parts of the app.
  ///
  /// A closely related widget is a modal bottom sheet, which is an alternative
  /// to a menu or a dialog and prevents the user from interacting with the rest
  /// of the app. Modal bottom sheets can be created and displayed with the
  /// [showModalBottomSheet] function.
  ///
  /// Unlike the persistent bottom sheet displayed by [showBottomSheet]
  /// this bottom sheet is not a [LocalHistoryEntry] and cannot be dismissed
  /// with the scaffold appbar's back button.
  ///
  /// If a persistent bottom sheet created with [showBottomSheet] is already
  /// visible, it must be closed before building the Scaffold with a new
  /// [bottomSheet].
  ///
  /// The value of [bottomSheet] can be any widget at all. It's unlikely to
  /// actually be a [BottomSheet], which is used by the implementations of
  /// [showBottomSheet] and [showModalBottomSheet]. Typically it's a widget
  /// that includes [Material].
  ///
  /// See also:
  ///
  ///  * [showBottomSheet], which displays a bottom sheet as a route that can
  ///    be dismissed with the scaffold's back button.
  ///  * [showModalBottomSheet], which displays a modal bottom sheet.
  final Widget? bottomSheet;

  /// If true the [body] and the scaffold's floating widgets should size
  /// themselves to avoid the onscreen keyboard whose height is defined by the
  /// ambient [MediaQuery]'s [MediaQueryData.viewInsets] `bottom` property.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// scaffold, the body can be resized to avoid overlapping the keyboard, which
  /// prevents widgets inside the body from being obscured by the keyboard.
  ///
  /// Defaults to true.
  final bool? resizeToAvoidBottomInset;

  /// Whether this scaffold is being displayed at the top of the screen.
  ///
  /// If true then the height of the [appBar] will be extended by the height
  /// of the screen's status bar, i.e. the top padding for [MediaQuery].
  ///
  /// The default value of this property, like the default value of
  /// [AppBar.primary], is true.
  final bool primary;

  /// {@macro flutter.material.DrawerController.dragStartBehavior}
  final DragStartBehavior drawerDragStartBehavior;

  /// The width of the area within which a horizontal swipe will open the
  /// drawer.
  ///
  /// By default, the value used is 20.0 added to the padding edge of
  /// `MediaQuery.of(context).padding` that corresponds to the surrounding
  /// [TextDirection]. This ensures that the drag area for notched devices is
  /// not obscured. For example, if `TextDirection.of(context)` is set to
  /// [TextDirection.ltr], 20.0 will be added to
  /// `MediaQuery.of(context).padding.left`.
  final double? drawerEdgeDragWidth;

  /// Determines if the [Scaffold.drawer] can be opened with a drag
  /// gesture.
  ///
  /// By default, the drag gesture is enabled.
  final bool drawerEnableOpenDragGesture;

  /// Determines if the [Scaffold.endDrawer] can be opened with a
  /// drag gesture.
  ///
  /// By default, the drag gesture is enabled.
  final bool endDrawerEnableOpenDragGesture;

  /// Restoration ID to save and restore the state of the [Scaffold].
  ///
  /// If it is non-null, the scaffold will persist and restore whether the
  /// [drawer] and [endDrawer] was open or closed.
  ///
  /// The state of this widget is persisted in a [RestorationBucket] claimed
  /// from the surrounding [RestorationScope] using the provided restoration ID.
  ///
  /// See also:
  ///
  ///  * [RestorationManager], which explains how state restoration works in
  ///    Flutter.
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    return MaterialAdapter.scaffoldBuilder!.call(context, this);
  }
}

/// An interface for controlling a feature of a [Scaffold].
///
/// Commonly obtained from [ScaffoldMessengerState.showSnackBar] or
/// [ScaffoldState.showBottomSheet].
class ScaffoldFeatureController<T extends Widget, U> {
  const ScaffoldFeatureController._(
      this._widget, this._completer, this.close, this.setState);
  final T _widget;
  final Completer<U> _completer;

  /// Completes when the feature controlled by this object is no longer visible.
  Future<U> get closed => _completer.future;

  /// Remove the feature (e.g., bottom sheet, snack bar, or material banner) from the scaffold.
  final VoidCallback close;

  /// Mark the feature (e.g., bottom sheet or snack bar) as needing to rebuild.
  final StateSetter? setState;
}

// TODO(guidezpl): Look into making this public. A copy of this class is in
//  bottom_sheet.dart, for now, https://github.com/flutter/flutter/issues/51627
/// A curve that progresses linearly until a specified [startingPoint], at which
/// point [curve] will begin. Unlike [Interval], [curve] will not start at zero,
/// but will use [startingPoint] as the Y position.
///
/// For example, if [startingPoint] is set to `0.5`, and [curve] is set to
/// [Curves.easeOut], then the bottom-left quarter of the curve will be a
/// straight line, and the top-right quarter will contain the entire contents of
/// [Curves.easeOut].
///
/// This is useful in situations where a widget must track the user's finger
/// (which requires a linear animation), and afterwards can be flung using a
/// curve specified with the [curve] argument, after the finger is released. In
/// such a case, the value of [startingPoint] would be the progress of the
/// animation at the time when the finger was released.
///
/// The [startingPoint] and [curve] arguments must not be null.
class _BottomSheetSuspendedCurve extends ParametricCurve<double> {
  /// Creates a suspended curve.
  const _BottomSheetSuspendedCurve(
    this.startingPoint, {
    this.curve = Curves.easeOutCubic,
  })  : assert(startingPoint != null),
        assert(curve != null);

  /// The progress value at which [curve] should begin.
  ///
  /// This defaults to [Curves.easeOutCubic].
  final double startingPoint;

  /// The curve to use when [startingPoint] is reached.
  final Curve curve;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    assert(startingPoint >= 0.0 && startingPoint <= 1.0);

    if (t < startingPoint) {
      return t;
    }

    if (t == 1.0) {
      return t;
    }

    final double curveProgress = (t - startingPoint) / (1 - startingPoint);
    final double transformed = curve.transform(curveProgress);
    return lerpDouble(startingPoint, 1, transformed)!;
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($startingPoint, $curve)';
  }
}

class _StandardBottomSheet extends StatefulWidget {
  const _StandardBottomSheet({
    Key? key,
    required this.animationController,
    this.enableDrag = true,
    required this.onClosing,
    required this.onDismissed,
    required this.builder,
    this.isPersistent = false,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.constraints,
  }) : super(key: key);

  final AnimationController
      animationController; // we control it, but it must be disposed by whoever created it.
  final bool enableDrag;
  final VoidCallback? onClosing;
  final VoidCallback? onDismissed;
  final WidgetBuilder builder;
  final bool isPersistent;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final BoxConstraints? constraints;

  @override
  _StandardBottomSheetState createState() => _StandardBottomSheetState();
}

class _StandardBottomSheetState extends State<_StandardBottomSheet> {
  ParametricCurve<double> animationCurve = _standardBottomSheetCurve;

  @override
  void initState() {
    super.initState();
    assert(widget.animationController != null);
    assert(
      widget.animationController.status == AnimationStatus.forward ||
          widget.animationController.status == AnimationStatus.completed,
    );
    widget.animationController.addStatusListener(_handleStatusChange);
  }

  @override
  void didUpdateWidget(_StandardBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.animationController == oldWidget.animationController);
  }

  void close() {
    assert(widget.animationController != null);
    widget.animationController.reverse();
    widget.onClosing?.call();
  }

  void _handleDragStart(DragStartDetails details) {
    // Allow the bottom sheet to track the user's finger accurately.
    animationCurve = Curves.linear;
  }

  void _handleDragEnd(DragEndDetails details, {bool? isClosing}) {
    // Allow the bottom sheet to animate smoothly from its current position.
    animationCurve = _BottomSheetSuspendedCurve(
      widget.animationController.value,
      curve: _standardBottomSheetCurve,
    );
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      widget.onDismissed?.call();
    }
  }

  bool extentChanged(DraggableScrollableNotification notification) {
    return false;
  }

  Widget _wrapBottomSheet(Widget bottomSheet) {
    return Semantics(
      container: true,
      onDismiss: close,
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: extentChanged,
        child: bottomSheet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (BuildContext context, Widget? child) {
        return Align(
          alignment: AlignmentDirectional.topStart,
          heightFactor:
              animationCurve.transform(widget.animationController.value),
          child: child,
        );
      },
      child: _wrapBottomSheet(
        BottomSheet(
          animationController: widget.animationController,
          enableDrag: widget.enableDrag,
          onDragStart: _handleDragStart,
          onDragEnd: _handleDragEnd,
          onClosing: widget.onClosing!,
          builder: widget.builder,
          backgroundColor: widget.backgroundColor,
          elevation: widget.elevation,
          shape: widget.shape,
          clipBehavior: widget.clipBehavior,
          constraints: widget.constraints,
        ),
      ),
    );
  }
}

/// A [ScaffoldFeatureController] for standard bottom sheets.
///
/// This is the type of objects returned by [ScaffoldState.showBottomSheet].
///
/// This controller is used to display both standard and persistent bottom
/// sheets. A bottom sheet is only persistent if it is set as the
/// [Scaffold.bottomSheet].
class PersistentBottomSheetController<T>
    extends ScaffoldFeatureController<_StandardBottomSheet, T> {
  const PersistentBottomSheetController._(
    _StandardBottomSheet widget,
    Completer<T> completer,
    VoidCallback close,
    StateSetter setState,
    this._isLocalHistoryEntry,
  ) : super._(widget, completer, close, setState);

  final bool _isLocalHistoryEntry;
}

class _ScaffoldScope extends InheritedWidget {
  const _ScaffoldScope({
    Key? key,
    required this.hasDrawer,
    required this.geometryNotifier,
    required Widget child,
  })  : assert(hasDrawer != null),
        super(key: key, child: child);

  final bool hasDrawer;
  final _ScaffoldGeometryNotifier geometryNotifier;

  @override
  bool updateShouldNotify(_ScaffoldScope oldWidget) {
    return hasDrawer != oldWidget.hasDrawer;
  }
}
