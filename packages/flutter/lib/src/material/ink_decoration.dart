// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'material.dart';

/// A convenience widget for drawing images and other decorations on [Material]
/// widgets, so that [InkWell] and [InkResponse] splashes will render over them.
///
/// Ink splashes and highlights, as rendered by [InkWell] and [InkResponse],
/// draw on the actual underlying [Material], under whatever widgets are drawn
/// over the material (such as [Text] and [Icon]s). If an opaque image is drawn
/// over the [Material] (maybe using a [Container] or [DecoratedBox]), these ink
/// effects will not be visible, as they will be entirely obscured by the opaque
/// graphics drawn above the [Material].
///
/// This widget draws the given [Decoration] directly on the [Material], in the
/// same way that [InkWell] and [InkResponse] draw there. This allows the
/// splashes to be drawn above the otherwise opaque graphics.
///
/// An alternative solution is to use a [MaterialType.transparency] material
/// above the opaque graphics, so that the ink responses from [InkWell]s and
/// [InkResponse]s will be drawn on the transparent material on top of the
/// opaque graphics, rather than under the opaque graphics on the underlying
/// [Material].
///
/// ## Limitations
///
/// This widget is subject to the same limitations as other ink effects, as
/// described in the documentation for [Material]. Most notably, the position of
/// an [Ink] widget must not change during the lifetime of the [Material] object
/// unless a [LayoutChangedNotification] is dispatched each frame that the
/// position changes. This is done automatically for [ListView] and other
/// scrolling widgets, but is not done for animated transitions such as
/// [SlideTransition].
///
/// Additionally, if multiple [Ink] widgets paint on the same [Material] in the
/// same location, their relative order is not guaranteed. The decorations will
/// be painted in the order that they were added to the material, which
/// generally speaking will match the order they are given in the widget tree,
/// but this order may appear to be somewhat random in more dynamic situations.
///
/// {@tool snippet}
///
/// This example shows how a [Material] widget can have a yellow rectangle drawn
/// on it using [Ink], while still having ink effects over the yellow rectangle:
///
/// ```dart
/// Material(
///   color: Colors.teal[900],
///   child: Center(
///     child: Ink(
///       color: Colors.yellow,
///       width: 200.0,
///       height: 100.0,
///       child: InkWell(
///         onTap: () { /* ... */ },
///         child: const Center(
///           child: Text('YELLOW'),
///         )
///       ),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// The following example shows how an image can be printed on a [Material]
/// widget with an [InkWell] above it:
///
/// ```dart
/// Material(
///   color: Colors.grey[800],
///   child: Center(
///     child: Ink.image(
///       image: const AssetImage('cat.jpeg'),
///       fit: BoxFit.cover,
///       width: 300.0,
///       height: 200.0,
///       child: InkWell(
///         onTap: () { /* ... */ },
///         child: const Align(
///           alignment: Alignment.topLeft,
///           child: Padding(
///             padding: EdgeInsets.all(10.0),
///             child: Text(
///               'KITTEN',
///               style: TextStyle(
///                 fontWeight: FontWeight.w900,
///                 color: Colors.white,
///               ),
///             ),
///           ),
///         )
///       ),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Container], a more generic form of this widget which paints itself,
///    rather that deferring to the nearest [Material] widget.
///  * [InkDecoration], the [InkFeature] subclass used by this widget to paint
///    on [Material] widgets.
///  * [InkWell] and [InkResponse], which also draw on [Material] widgets.
class Ink extends StatelessWidget {
  /// Paints a decoration (which can be a simple color) on a [Material].
  ///
  /// The [height] and [width] values include the [padding].
  ///
  /// The `color` argument is a shorthand for
  /// `decoration: BoxDecoration(color: color)`, which means you cannot supply
  /// both a `color` and a `decoration` argument. If you want to have both a
  /// `color` and a `decoration`, you can pass the color as the `color`
  /// argument to the `BoxDecoration`.
  ///
  /// If there is no intention to render anything on this decoration, consider
  /// using a [Container] with a [BoxDecoration] instead.
  Ink({
    Key? key,
    this.padding,
    Color? color,
    Decoration? decoration,
    this.width,
    this.height,
    this.child,
  })  : assert(padding == null || padding.isNonNegative),
        assert(decoration == null || decoration.debugAssertIsValid()),
        assert(
          color == null || decoration == null,
          'Cannot provide both a color and a decoration\n'
          'The color argument is just a shorthand for "decoration: BoxDecoration(color: color)".',
        ),
        decoration =
            decoration ?? (color != null ? BoxDecoration(color: color) : null),
        super(key: key);

  /// Creates a widget that shows an image (obtained from an [ImageProvider]) on
  /// a [Material].
  ///
  /// This argument is a shorthand for passing a [BoxDecoration] that has only
  /// its [BoxDecoration.image] property set to the [Ink] constructor. The
  /// properties of the [DecorationImage] of that [BoxDecoration] are set
  /// according to the arguments passed to this method.
  ///
  /// The `image` argument must not be null. If there is no
  /// intention to render anything on this image, consider using a
  /// [Container] with a [BoxDecoration.image] instead. The `onImageError`
  /// argument may be provided to listen for errors when resolving the image.
  ///
  /// The `alignment`, `repeat`, and `matchTextDirection` arguments must not
  /// be null either, but they have default values.
  ///
  /// See [paintImage] for a description of the meaning of these arguments.
  Ink.image({
    Key? key,
    this.padding,
    required ImageProvider image,
    ImageErrorListener? onImageError,
    ColorFilter? colorFilter,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Rect? centerSlice,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    bool matchTextDirection = false,
    this.width,
    this.height,
    this.child,
  })  : assert(padding == null || padding.isNonNegative),
        assert(image != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        decoration = BoxDecoration(
          image: DecorationImage(
            image: image,
            onError: onImageError,
            colorFilter: colorFilter,
            fit: fit,
            alignment: alignment,
            centerSlice: centerSlice,
            repeat: repeat,
            matchTextDirection: matchTextDirection,
          ),
        ),
        super(key: key);

  /// The [child] contained by the container.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// Empty space to inscribe inside the [decoration]. The [child], if any, is
  /// placed inside this padding.
  ///
  /// This padding is in addition to any padding inherent in the [decoration];
  /// see [Decoration.padding].
  final EdgeInsetsGeometry? padding;

  /// The decoration to paint on the nearest ancestor [Material] widget.
  ///
  /// A shorthand for specifying just a solid color is available in the
  /// constructor: set the `color` argument instead of the `decoration`
  /// argument.
  ///
  /// A shorthand for specifying just an image is also available using the
  /// [Ink.image] constructor.
  final Decoration? decoration;

  /// A width to apply to the [decoration] and the [child]. The width includes
  /// any [padding].
  final double? width;

  /// A height to apply to the [decoration] and the [child]. The height includes
  /// any [padding].
  final double? height;

  EdgeInsetsGeometry get _paddingIncludingDecoration {
    if (decoration == null || decoration!.padding == null)
      return padding ?? EdgeInsets.zero;
    final EdgeInsetsGeometry decorationPadding = decoration!.padding!;
    if (padding == null) return decorationPadding;
    return padding!.add(decorationPadding);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding,
        defaultValue: null));
    properties.add(
        DiagnosticsProperty<Decoration>('bg', decoration, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    return child ?? Container();
  }
}
