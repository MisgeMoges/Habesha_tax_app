import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'ios_scroll_physics.dart';

/// A wrapper widget that ensures proper scrolling behavior on iOS
class ScrollableWrapper extends StatelessWidget {
  final Widget child;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool primary;
  final ScrollController? controller;

  const ScrollableWrapper({
    super.key,
    required this.child,
    this.physics,
    this.padding,
    this.primary = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: physics ?? getPlatformScrollPhysics(),
      padding: padding,
      primary: primary,
      controller: controller,
      child: child,
    );
  }
}

/// A wrapper for ListView that ensures proper scrolling on iOS
class ListViewWrapper extends StatelessWidget {
  final List<Widget> children;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool primary;
  final bool shrinkWrap;
  final ScrollController? controller;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;

  const ListViewWrapper({
    super.key,
    required this.children,
    this.physics,
    this.padding,
    this.primary = true,
    this.shrinkWrap = false,
    this.controller,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: physics ?? getPlatformScrollPhysics(),
      padding: padding,
      primary: primary,
      shrinkWrap: shrinkWrap,
      controller: controller,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      children: children,
    );
  }
}

/// A wrapper for ListView.builder that ensures proper scrolling on iOS
class ListViewBuilderWrapper extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool primary;
  final bool shrinkWrap;
  final ScrollController? controller;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;

  const ListViewBuilderWrapper({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.physics,
    this.padding,
    this.primary = true,
    this.shrinkWrap = false,
    this.controller,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      physics: physics ?? getPlatformScrollPhysics(),
      padding: padding,
      primary: primary,
      shrinkWrap: shrinkWrap,
      controller: controller,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
    );
  }
}
