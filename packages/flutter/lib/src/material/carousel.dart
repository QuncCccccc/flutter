// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';

/// A Material Design carousel.
///
/// This is a scrollable list where the size of each item can change dynamically
/// based on different layouts.
///
/// Material Design 3 introduces 4 layouts for [Carousel]:
///  * Multi-browse: This layout shows at least one large, medium, and small
/// carousel item at a time.
///  * Uncontained: This layout show items that scroll to the edge of the container.
///  * Hero: This layout shows at least one large and one small item at a time.
///  * Full-screen: This layout shows one edge-to-edge large item at a time and
/// scrolls vertically.
///
/// By default, [Carousel] has a uncontained layout. It shows like a [ListView]
/// and its children are a single size.
///
/// The [CarouselController] can be used to control the [CarouselController.initialItem].
///
/// [Carousel.itemExtent] must be non-null. Even though the children [Carousel]
/// have a single size, the first and last items can be squished a little while
/// scrolling and the minimum squished size is determined by [shrinkExtent].
///
/// {@tool dartpad}
/// Here is an example of [Carousel].
///
/// ** See code in examples/api/lib/material/carousel/carousel.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [CarouselController], which controls which item is the first visible in
/// the view.
///  * [PageView], which is a scrollable list that works page by page.
class Carousel extends StatefulWidget {
  /// Creates a Material Design carousel.
  const Carousel({
    super.key,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.overlayColor,
    this.itemSnapping = false,
    this.shrinkExtent,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.onTap,
    required this.itemExtent,
    required this.children,
  });

  /// The amount of space to surround each carousel item with.
  ///
  /// Defaults to EdgeInsets.all(4.0).
  final EdgeInsets? padding;

  /// The background color for each carousel item.
  ///
  /// Defaults to [ColorScheme.surface].
  final Color? backgroundColor;

  /// The z-coordinate of each carousel item.
  ///
  /// Defaults to 0.0.
  final double? elevation;

  /// The shape of each carousel item's [Material].
  ///
  /// Defines each item's [Material.shape].
  ///
  /// Defaults to a [RoundedRectangleBorder] with a circular corner radius
  /// of 28.0.
  final ShapeBorder? shape;

  /// The highlight color to indicate the carousel items are in pressed, hovered
  /// or focused states.
  ///
  /// The default values are:
  ///   * pressed - Theme.colorScheme.onSurface(0.1)
  ///   * hovered - Theme.colorScheme.onSurface(0.08)
  ///   * focused - Theme.colorScheme.onSurface(0.1)
  final WidgetStateProperty<Color?>? overlayColor;

  /// The minimum extent that each carousel item can be.
  ///
  /// While scrolling, the first visible item will be pinned and keep shrinking
  /// until this extent, then it is scrolled off screen; the last visible item
  /// will show on screen with this size and keep expanding until the
  /// [itemExtent]. So if this is 0.0, then the item should shrink/expand to/from
  /// 0.0 from/to the [itemExtent].
  ///
  /// However, if the remaining extent of the viewport for the last visible item
  /// is bigger than [shrinkExtent], [shrinkExtent] will be adjusted to be the
  /// remaining extent for a smooth size transition during scrolling.
  ///
  /// Defaults to 0.0.
  final double? shrinkExtent;

  /// Whether the carousel should keep scrolling to the next/previous items to
  /// maintain the original layout.
  ///
  /// Defaults to false.
  final bool itemSnapping;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  final CarouselController? controller;

  /// The [Axis] along which the scroll view's offset increases with each page.
  ///
  /// Defaults to [Axis.horizontal].
  final Axis scrollDirection;

  /// Whether the carousel list scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [scrollDirection] is [Axis.horizontal], then the carousel scrolls from
  /// left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the page view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// Called when one of the [children] is tapped.
  final ValueChanged<int>? onTap;

  /// The extent the children are forced to have in the main axis.
  final double? itemExtent;

  /// The child widgets for carousel.
  final List<Widget> children;

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  late double? itemExtent;
  CarouselController? _internalController;
  CarouselController get _controller => widget.controller ?? _internalController!;

  @override
  void initState() {
    if (widget.controller == null) {
      _internalController = CarouselController();
    }
    _controller._attach(this);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    itemExtent = getItemExtent();
  }

  @override
  void didUpdateWidget(covariant Carousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach(this);
      if (widget.controller != null) {
        _internalController?._detach(this);
        _internalController = null;
        widget.controller?._attach(this);
      }
    }
    if (widget.itemExtent != oldWidget.itemExtent) {
      itemExtent = getItemExtent();
    }
  }

  @override
  void dispose() {
    _controller._detach(this);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  AxisDirection _getDirection(BuildContext context) {
    switch (widget.scrollDirection) {
      case Axis.horizontal:
        assert(debugCheckHasDirectionality(context));
        final TextDirection textDirection = Directionality.of(context);
        final AxisDirection axisDirection = textDirectionToAxisDirection(textDirection);
        return widget.reverse ? flipAxisDirection(axisDirection) : axisDirection;
      case Axis.vertical:
        return widget.reverse ? AxisDirection.up : AxisDirection.down;
    }
  }

  double? getItemExtent() {
    if (widget.itemExtent != null) {
      final double screenExtent = switch(widget.scrollDirection) {
        Axis.horizontal => MediaQuery.of(context).size.width,
        Axis.vertical => MediaQuery.of(context).size.height,
      };

      return clampDouble(widget.itemExtent!, 0, screenExtent);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AxisDirection axisDirection = _getDirection(context);
    final ScrollPhysics physics = widget.itemSnapping
      ? const CarouselScrollPhysics()
      : ScrollConfiguration.of(context).getScrollPhysics(context);
    final EdgeInsets effectivePadding = widget.padding ?? const EdgeInsets.all(4.0);
    final Color effectiveBackgroundColor = widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
    final double effectiveElevation = widget.elevation ?? 0.0;
    final ShapeBorder effectiveShape = widget.shape
      ?? const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28.0))
      );

    final List<Widget> children = List<Widget>.generate(widget.children.length, (int index) {
      return Padding(
        padding: effectivePadding,
        child: Material(
          clipBehavior: Clip.antiAlias,
          color: effectiveBackgroundColor,
          elevation: effectiveElevation,
          shape: effectiveShape,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              widget.children.elementAt(index),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    widget.onTap?.call(index);
                  },
                  overlayColor: widget.overlayColor ?? WidgetStateProperty.resolveWith((Set<WidgetState> states) {
                    if (states.contains(WidgetState.pressed)) {
                      return theme.colorScheme.onSurface.withOpacity(0.1);
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return theme.colorScheme.onSurface.withOpacity(0.08);
                    }
                    if (states.contains(WidgetState.focused)) {
                      return theme.colorScheme.onSurface.withOpacity(0.1);
                    }
                    return null;
                  }),
                ),
              ),
            ],
          ),
        ),
      );
    });

    return Scrollable(
      axisDirection: axisDirection,
      controller: _controller,
      physics: physics,
      viewportBuilder: (BuildContext context, ViewportOffset position) {
        return Viewport(
          cacheExtent: 0.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          axisDirection: axisDirection,
          offset: position,
          clipBehavior: Clip.antiAlias,
          slivers: <Widget>[
            _SliverFixedExtentCarousel(
              itemExtent: itemExtent!,
              minExtent: widget.shrinkExtent ?? 0.0,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return children.elementAt(index);
                },
                childCount: children.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

// A sliver that places its box children in a linear array and constrains them
// to have a fixed extent.
//
// _To learn more about slivers, see [CustomScrollView.slivers]._
//
// This sliver list arranges its children in a line along the main axis starting
// at offset zero and without gaps. Each child is constrained to a fixed extent
// along the main axis and the [SliverConstraints.crossAxisExtent]
// along the cross axis. The difference between this and a list view with a fixed
// extent is the first item and last item can be squished a little based on the
// value of [minExtent], as the [Carousel spces](https://m3.material.io/components/carousel/guidelines#96c5c157-fe5b-4ee3-a9b4-72bf8efab7e9) indicates.
class _SliverFixedExtentCarousel extends SliverMultiBoxAdaptorWidget {
  const _SliverFixedExtentCarousel({
    required super.delegate,
    required this.minExtent,
    required this.itemExtent,
  });

  final double itemExtent;
  final double minExtent;

  @override
  RenderSliverFixedExtentBoxAdaptor createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return _RenderSliverFixedExtentCarousel(
      childManager: element,
      minExtent: minExtent,
      maxExtent: itemExtent,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSliverFixedExtentCarousel renderObject) {
    renderObject.maxExtent = itemExtent;
  }
}

class _RenderSliverFixedExtentCarousel extends RenderSliverFixedExtentBoxAdaptor {
  _RenderSliverFixedExtentCarousel({
    required super.childManager,
    required double maxExtent,
    required double minExtent,
  }) : _maxExtent = maxExtent,
       _minExtent = minExtent;

  double get maxExtent => _maxExtent;
  double _maxExtent;
  set maxExtent(double value) {
    if (_maxExtent == value) {
      return;
    }
    _maxExtent = value;
    markNeedsLayout();
  }

  double get minExtent => _minExtent;
  double _minExtent;
  set minExtent(double value) {
    if (_minExtent == value) {
      return;
    }
    _minExtent = value;
    markNeedsLayout();
  }

  // This implements the [itemExtentBuilder] callback.
  double _buildItemExtent(int index, SliverLayoutDimensions currentLayoutDimensions) {
    final int firstVisibleIndex = (constraints.scrollOffset / maxExtent).floor();

    // Calculate how many items have been completely scroll off screen.
    final int offscreenItems = (constraints.scrollOffset / maxExtent).floor();

    // If there is an item is partually off screen and partually on screen, `constraints.scrollOffset`
    // must be greater than `offscreenItems * maxExtent`, so the difference
    // between these two is how much the current first visible item is off screen.
    final double offscreenExtent = constraints.scrollOffset - offscreenItems * maxExtent;

    // If there is not enough space to place the last visible item but the remaining
    // space is larger than `minExtent`, the extent for last item should be at
    // least the remaining extent to make sure a smooth size transition.
    final double effectiveMinExtent = math.max(constraints.remainingPaintExtent % maxExtent, minExtent);

    // Two special handles are the first and last visible items. Other items' extent
    // should all return `maxExtent`.
    if (index == firstVisibleIndex) {
      final double effectiveExtent = maxExtent - offscreenExtent;
      return math.max(effectiveExtent, effectiveMinExtent);
    }

    final double scrollOffsetForLastIndex = constraints.scrollOffset + constraints.remainingPaintExtent;
    if (index == getMaxChildIndexForScrollOffset(scrollOffsetForLastIndex, maxExtent)) {
      return clampDouble(scrollOffsetForLastIndex - maxExtent * index, effectiveMinExtent, maxExtent);
    }

    return maxExtent;
  }

  /// The layout offset for the child with the given index.
  @override
  double indexToLayoutOffset(
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
    int index,
  ) {
    final int firstVisibleIndex = (constraints.scrollOffset / maxExtent).floor();

    // If there is not enough space to place the last visible item but the remaining
    // space is larger than `minExtent`, the extent for last item should be at
    // least the remaining extent to make sure a smooth size transition.
    final double effectiveMinExtent = math.max(constraints.remainingPaintExtent % maxExtent, minExtent);
    if (index == firstVisibleIndex) {
      final double firstVisibleItemExtent = _buildItemExtent(index, currentLayoutDimensions);

      // If the first item is squished to be less than `effectievMinExtent`,
      // then it should stop changinng its size and should start to scroll off screen.
      if (firstVisibleItemExtent <= effectiveMinExtent) {
        return maxExtent * index - effectiveMinExtent + maxExtent;
      }
      return constraints.scrollOffset;
    }
    return maxExtent * index;
  }

  /// The minimum child index that is visible at the given scroll offset.
  @override
  int getMinChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    final int firstVisibleIndex = (constraints.scrollOffset / maxExtent).floor();
    return math.max(firstVisibleIndex, 0);
  }

  /// The maximum child index that is visible at the given scroll offset.
  @override
  int getMaxChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    if (maxExtent > 0.0) {
      final double actual = scrollOffset / maxExtent - 1;
      final int round = actual.round();
      if ((actual * maxExtent - round * maxExtent).abs() < precisionErrorTolerance) {
        return math.max(0, round);
      }
      return math.max(0, actual.ceil());
    }
    return 0;
  }

  @override
  double? get itemExtent => null;

  @override
  ItemExtentBuilder? get itemExtentBuilder => _buildItemExtent;
}

/// Scroll physics used by a [Carousel].
///
/// These physics cause the carousel item to snap to item boundaries.
///
/// See also:
///
///  * [ScrollPhysics], the base class which defines the API for scrolling
///    physics.
///  * [PageScrollPhysics], scroll physics used by a [PageView].
class CarouselScrollPhysics extends ScrollPhysics {
  /// Creates physics for a [Carousel].
  const CarouselScrollPhysics({super.parent});

  @override
  CarouselScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CarouselScrollPhysics(parent: buildParent(ancestor));
  }

  double _getTargetPixels(
    _CarouselPosition position,
    Tolerance tolerance,
    double velocity,
  ) {
    double fraction;
    fraction = position.itemExtent! / position.viewportDimension;

    final double itemWidth = position.viewportDimension * fraction;

    final double actual = math.max(0.0, position.pixels) / itemWidth;
    final double round = actual.roundToDouble();
    double item;
    if ((actual - round).abs() < precisionErrorTolerance) {
      item = round;
    }
    else {
      item = actual;
    }
    if (velocity < -tolerance.velocity) {
      item -= 0.5;
    } else if (velocity > tolerance.velocity) {
      item += 0.5;
    }
    return item.roundToDouble() * itemWidth;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    assert(
      position is _CarouselPosition,
      'CarouselScrollPhysics can only be used with Scrollables that uses '
      'the CarouselController',
    );

    final _CarouselPosition metrics = position as _CarouselPosition;
    if ((velocity <= 0.0 && metrics.pixels <= metrics.minScrollExtent) ||
        (velocity >= 0.0 && metrics.pixels >= metrics.maxScrollExtent)) {
      return super.createBallisticSimulation(metrics, velocity);
    }

    final Tolerance tolerance = toleranceFor(metrics);
    final double target = _getTargetPixels(metrics, tolerance, velocity);
    if (target != metrics.pixels) {
      return ScrollSpringSimulation(
        spring,
        metrics.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => true;
}

/// Metrics for a [Carousel].
class _CarouselMetrics extends FixedScrollMetrics {
  /// Creates an immutable snapshot of values associated with a [Carousel].
  _CarouselMetrics({
    required super.minScrollExtent,
    required super.maxScrollExtent,
    required super.pixels,
    required super.viewportDimension,
    required super.axisDirection,
    this.itemExtent,
    required super.devicePixelRatio,
  });

  @override
  _CarouselMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? itemExtent,
    double? devicePixelRatio,
  }) {
    return _CarouselMetrics(
      minScrollExtent: minScrollExtent ?? (hasContentDimensions ? this.minScrollExtent : null),
      maxScrollExtent: maxScrollExtent ?? (hasContentDimensions ? this.maxScrollExtent : null),
      pixels: pixels ?? (hasPixels ? this.pixels : null),
      viewportDimension: viewportDimension ?? (hasViewportDimension ? this.viewportDimension : null),
      axisDirection: axisDirection ?? this.axisDirection,
      itemExtent: itemExtent ?? this.itemExtent,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }

  /// Extent for carousel item.
  ///
  /// Used to compute the first item from the current [pixels].
  final double? itemExtent;
}


class _CarouselPosition extends ScrollPositionWithSingleContext implements _CarouselMetrics {
  _CarouselPosition({
    required super.physics,
    required super.context,
    this.initialItem = 0,
    required double itemExtent,
    super.oldPosition,
  }) : _itemExtent = itemExtent,
       _itemToShowOnStartup = initialItem.toDouble(),
       super(
         initialPixels: null
       );

  final int initialItem;
  final double _itemToShowOnStartup;
  // When the viewport has a zero-size, the `page` can not
  // be retrieved by `getPageFromPixels`, so we need to cache the page
  // for use when resizing the viewport to non-zero next time.
  double? _cachedItem;

  @override
  double? get itemExtent => _itemExtent;
  double? _itemExtent;
  set itemExtent(double? value) {
    if (_itemExtent == value) {
      return;
    }
    _itemExtent = value;
  }

  double getItemFromPixels(double pixels, double viewportDimension) {
    assert(viewportDimension > 0.0);
    final double fraction = itemExtent! / viewportDimension;

    final double actual = math.max(0.0, pixels) / (viewportDimension * fraction);
    final double round = actual.roundToDouble();
    if ((actual - round).abs() < precisionErrorTolerance) {
      return round;
    }
    return actual;
  }

  double getPixelsFromItem(double item) {
    final double fraction = itemExtent! / viewportDimension;

    return item * viewportDimension * fraction;
  }

  @override
  bool applyViewportDimension(double viewportDimension) {
    final double? oldViewportDimensions = hasViewportDimension ? this.viewportDimension : null;
    if (viewportDimension == oldViewportDimensions) {
      return true;
    }
    final bool result = super.applyViewportDimension(viewportDimension);
    final double? oldPixels = hasPixels ? pixels : null;
    double item;
    if (oldPixels == null) {
      item = _itemToShowOnStartup;
    } else if (oldViewportDimensions == 0.0) {
      // If resize from zero, we should use the _cachedItem to recover the state.
      item = _cachedItem!;
    } else {
      item = getItemFromPixels(oldPixels, oldViewportDimensions!);
    }
    final double newPixels = getPixelsFromItem(item);
    // If the viewportDimension is zero, cache the page
    // in case the viewport is resized to be non-zero.
    _cachedItem = (viewportDimension == 0.0) ? item : null;

    if (newPixels != oldPixels) {
      correctPixels(newPixels);
      return false;
    }
    return result;
  }

  @override
  _CarouselMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? itemExtent,
    List<int>? layoutWeights,
    double? devicePixelRatio,
  }) {
    return _CarouselMetrics(
      minScrollExtent: minScrollExtent ?? (hasContentDimensions ? this.minScrollExtent : null),
      maxScrollExtent: maxScrollExtent ?? (hasContentDimensions ? this.maxScrollExtent : null),
      pixels: pixels ?? (hasPixels ? this.pixels : null),
      viewportDimension: viewportDimension ?? (hasViewportDimension ? this.viewportDimension : null),
      axisDirection: axisDirection ?? this.axisDirection,
      itemExtent: itemExtent ?? this.itemExtent,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

/// A controller for [Carousel].
///
/// Using a carousel controller helps to show which item is fully expanded on
/// the carousel list.
class CarouselController extends ScrollController {
  /// Creates a carousel controller.
  CarouselController({
    this.initialItem = 0,
  });

  /// The item that expands to the maximum size when first creating the [Carousel].
  final int initialItem;

  _CarouselState? _carouselState;

  // ignore: use_setters_to_change_properties
  void _attach(_CarouselState anchor) {
    _carouselState = anchor;
  }

  void _detach(_CarouselState anchor) {
    if (_carouselState == anchor) {
      _carouselState = null;
    }
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) {
    assert(_carouselState != null);
    final double? itemExtent = _carouselState!.itemExtent;
    int expandedItem = initialItem;

    return _CarouselPosition(
      physics: physics,
      context: context,
      initialItem: expandedItem,
      itemExtent: itemExtent!,
      oldPosition: oldPosition,
    );
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    final _CarouselPosition carouselPosition = position as _CarouselPosition;
    carouselPosition.itemExtent = _carouselState!.itemExtent;
  }
}