import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

/// Custom scroll behavior for better iOS scrolling
class IOSScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Use iOS-style overscroll indicator
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return child;
    }
    return super.buildOverscrollIndicator(context, child, details);
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Use iOS-style scrollbar
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoScrollbar(child: child);
    }
    return super.buildScrollbar(context, child, details);
  }

  @override
  TargetPlatform getTargetPlatform(BuildContext context) {
    return defaultTargetPlatform;
  }
}
