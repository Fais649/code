import 'dart:math';

import 'package:flutter/material.dart';

class Spliter extends StatefulWidget {
  static const double dividerMainAxisSize = 80.0;

  final SplitMode mode;

  /// The main axis the children will lay out on.
  ///
  /// If [Axis.horizontal], the children will be placed in a [Row]
  /// and they will be horizontally resizable.
  ///
  /// If [Axis.vertical], the children will be placed in a [Column]
  /// and they will be vertically resizable.
  ///
  /// Cannot be null.
  final Axis axis;

  /// The child that will be laid out first along [axis].
  final Widget firstChild;

  /// The child that will be laid out last along [axis].
  final Widget secondChild;

  /// The fraction of the layout to allocate to [firstChild].
  ///
  /// [secondChild] will receive a fraction of `1 - initialFirstFraction`.
  final double initialFirstFraction;

  /// Builds a split oriented along [axis].
  const Spliter({
    Key key = const Key(""),
    required this.axis,
    required this.firstChild,
    required this.secondChild,
    double initialFirstFraction = 0.5,
    this.mode = SplitMode.normal,
  })  : initialFirstFraction = initialFirstFraction,
        super(key: key);

  /// The key passed to the divider between [firstChild] and [secondChild].
  ///
  /// Visible to grab it in tests.
  @visibleForTesting
  Key get dividerKey => Key('$this dividerKey');

  @override
  State<StatefulWidget> createState() => _SpliterState();
}

enum SplitMode { normal, leftExpand, rightExpand }

class _SpliterState extends State<Spliter> {
  static final Map<Key, double> _fractionMap = {};
  double get firstFraction => _fractionMap[widget.key] ?? 0;
  set firstFraction(double value) => _fractionMap[widget.key as Key] = value;
  bool get isHorizontal => widget.axis == Axis.horizontal;
  double get secondFraction => 1 - firstFraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildLayout);
  }

  @override
  void initState() {
    super.initState();
    if (!_fractionMap.containsKey(widget.key)) {
      _fractionMap[widget.key as Key] = widget.initialFirstFraction;
    }
  }

  Widget _buildLayout(BuildContext context, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final axisSize = isHorizontal ? width : height;
    final crossAxisSize = isHorizontal ? height : width;
    const halfDivider = Spliter.dividerMainAxisSize / 2.0;

    // Determine what fraction to give each child, including enough space to
    // display the divider.
    double firstSize = axisSize * firstFraction;
    double secondSize = axisSize * secondFraction;

    // Clamp the sizes to be sure there is enough space for the dividers.
    firstSize = firstSize.clamp(halfDivider, axisSize - halfDivider);
    secondSize = secondSize.clamp(halfDivider, axisSize - halfDivider);

    // Remove space from each child to place the divider in the middle.
    firstSize = firstSize - halfDivider;
    secondSize = secondSize - halfDivider;

    void updateSpacing(DragUpdateDetails dragDetails) {
      final delta = isHorizontal ? dragDetails.delta.dx : dragDetails.delta.dy;
      final fractionalDelta = delta / axisSize;
      setState(() {
        // Update the fraction of space consumed by the children,
        // being sure not to allocate any negative space.
        firstFraction += fractionalDelta;
        firstFraction = firstFraction.clamp(0.0, 1.0);
      });
    }

    // TODO(https://github.com/flutter/flutter/issues/43747): use an icon.
    // The material icon for a drag handle is not currently available.
    // For now, draw an indicator that is 3 lines running in the direction
    // of the main axis, like a hamburger menu.
    // TODO(https://github.com/flutter/devtools/issues/1265): update mouse
    // to indicate that this is resizable.
    final dragIndicator = Flex(
      direction: isHorizontal ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < min(crossAxisSize / 6.0, 3).floor(); i++)
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: isHorizontal ? 2.0 : 0.0,
              horizontal: isHorizontal ? 0.0 : 2.0,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).indicatorColor,
                borderRadius:
                    BorderRadius.circular(Spliter.dividerMainAxisSize),
              ),
              child: SizedBox(
                height: isHorizontal ? 2.0 : Spliter.dividerMainAxisSize - 2.0,
                width: isHorizontal ? Spliter.dividerMainAxisSize - 2.0 : 2.0,
              ),
            ),
          ),
      ],
    );
    const size = 8.0;
    final children = [
      widget.mode == SplitMode.leftExpand
          ? Expanded(child: widget.firstChild)
          : SizedBox(
              width: isHorizontal ? firstSize : width,
              height: isHorizontal ? height : firstSize,
              child: widget.firstChild,
            ),
      MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          color: Colors.black,
          child: GestureDetector(
            key: widget.dividerKey,
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: isHorizontal ? updateSpacing : null,
            onVerticalDragUpdate: isHorizontal ? null : updateSpacing,
            child: SizedBox(
              width: isHorizontal ? size : width,
              height: isHorizontal ? height : size,
              child: Center(
                child: Container(
                  height:
                      !isHorizontal ? 2.0 : Spliter.dividerMainAxisSize - 2.0,
                  width:
                      !isHorizontal ? Spliter.dividerMainAxisSize - 2.0 : 2.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      widget.mode == SplitMode.rightExpand
          ? Expanded(child: widget.secondChild)
          : SizedBox(
              width: isHorizontal ? secondSize : width,
              height: isHorizontal ? height : secondSize,
              child: widget.secondChild,
            ),
    ];
    return Flex(direction: widget.axis, children: children);
  }
}
