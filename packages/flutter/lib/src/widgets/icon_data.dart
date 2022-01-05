// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// A description of an icon fulfilled by a font glyph.
///
/// See [Icons] for a number of predefined icons available for material
/// design applications.
@immutable
class IconData {
  /// Creates icon data.
  ///
  /// Rarely used directly. Instead, consider using one of the predefined icons
  /// like the [Icons] collection.
  ///
  /// The [fontPackage] argument must be non-null when using a font family that
  /// is included in a package. This is used when selecting the font.
  const IconData(this.url);

  /// The Unicode code point at which this icon is stored in the icon font.
  final String url;
}
