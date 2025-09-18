import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Custom scroll physics that provides better scrolling behavior on iOS
class IOSScrollPhysics extends ScrollPhysics {
  const IOSScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  IOSScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return IOSScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Use iOS-style boundary conditions
    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    if (position.maxScrollExtent <= position.pixels &&
        position.pixels < value) {
      return value - position.pixels;
    }
    if (value < position.minScrollExtent &&
        position.minScrollExtent < position.pixels) {
      return value - position.minScrollExtent;
    }
    if (position.pixels < position.maxScrollExtent &&
        position.maxScrollExtent < value) {
      return value - position.maxScrollExtent;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Use iOS-style ballistic simulation
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = this.tolerance;
    final target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  double _getTargetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    return position.pixels + velocity * 0.5;
  }
}

/// Get platform-appropriate scroll physics
ScrollPhysics getPlatformScrollPhysics({ScrollPhysics? parent}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    // Use BouncingScrollPhysics for iOS to get the native iOS bounce effect
    return BouncingScrollPhysics(parent: parent);
  }
  return AlwaysScrollableScrollPhysics(parent: parent);
}

/// Always scrollable physics with iOS-style behavior
class AlwaysScrollableIOSPhysics extends AlwaysScrollableScrollPhysics {
  const AlwaysScrollableIOSPhysics({ScrollPhysics? parent})
    : super(parent: parent);

  @override
  AlwaysScrollableIOSPhysics applyTo(ScrollPhysics? ancestor) {
    return AlwaysScrollableIOSPhysics(parent: buildParent(ancestor));
  }

  @override
  ScrollPhysics buildParent(ScrollPhysics? ancestor) {
    return IOSScrollPhysics(parent: ancestor);
  }
}
