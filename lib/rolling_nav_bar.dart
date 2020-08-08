import 'dart:math';

import 'indexed.dart';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:polygon_clipper/polygon_clipper.dart';
import 'package:tinycolor/tinycolor.dart';

enum Direction { forward, backward, stationary }
enum AnimationType { roll, shrinkOutIn, snap, spinOutIn }
typedef Widget RollingNavBarChildBuilder(
  BuildContext context,
  int index,
  AnimationInfo animationInfo,
  AnimationUpdate animationUpdate,
);

/// Container for the most primitive data necessary to drive our animation with
/// functions to yield the next tier of calculated data for the animation.
class AnimationInfo {
  /// Number of sides for the active indicator - e.g., 6 is a hexagon.
  final int numSides;

  /// Index toward which the active indicator is heading.
  final int newIndex;

  /// Index from which the active indicator is leaving.
  final int oldIndex;

  /// The amount of sides on the active indicator that it should roll as it
  /// traverses each list item. Calibrated to create a realistic rolling motion.
  final double sidesPerListItem;

  /// The amount of rotation applied to the active indicator at the start of
  /// this transition.
  final double startingRotation;

  AnimationInfo({
    @required this.newIndex,
    @required this.numSides,
    @required this.oldIndex,
    @required this.sidesPerListItem,
    @required this.startingRotation,
  });

  Direction get direction =>
      newIndex > oldIndex ? Direction.forward : Direction.backward;
  int get indexDelta => (newIndex - oldIndex).abs();

  /// Percent of a full rotation an active indicator should see for each of its
  /// sides.
  double get radiansPerSide => 2 * pi / numSides;

  /// Total rotation required to reach the new index.
  ///
  /// Note that this is correct because the active indicator holds its rotation
  /// value when it gets to an index. So when the user clicks on Tab 2, the
  /// indicator rolls there and holds. Imagine that it rolls 180°, or pi radians,
  /// and then is followed up by a click on thie third tab, requiring yet another
  /// 180° or pi radians. This number indicates that to reach the third tab,
  /// a total rotation value of 2pi radians is required, but already stored is
  /// that the active indicator has rotated pi radians (or 180°).
  double get radiansToRotate => newIndex * radiansPerSide * sidesPerListItem;

  /// Total rotation required to reach the new index, minus what has already
  /// been rotated. This number is fixed from the beginning of the transition
  /// and does not update as the active indicator animates.
  double get radiansToRotateDelta => direction == Direction.forward
      ? radiansToRotate - startingRotation
      : startingRotation - radiansToRotate;
}

/// Container for the state of a [RollingNavBar]'s animation, useful for syncing
/// visual effects elsewhere in your app with nav bar animation progress.
class AnimationUpdate {
  /// The relative value of the animation, taking into account the selected
  /// curve.
  final double animationValue;

  /// The current color of the active indicator as it is (optionally) linearly
  /// interpolated.
  final Color color;

  /// Whether the user has selected a tab before or after the previous tab.
  final Direction direction;

  /// The absolute value or progress of the animation, without taking into
  /// account the selected curve.
  final double percentAnimated;

  /// The current rotation of the active indicator, in radians.
  final double rotation;
  AnimationUpdate({
    @required this.animationValue,
    @required this.color,
    @required this.direction,
    @required this.percentAnimated,
    @required this.rotation,
  });
}

/// Bottom nav bar with playful and customizable transitions between active
/// states.
///
/// This widget is suitable for the bottom of a [Stack] or a [Scaffold]'s
/// `bottomNavigationBar` slot, though in the latter, a sizing wrapping widget
/// is required.
///
/// [RollingNavBar] has two named constructors, `children` and `iconData`, and
/// no default constructor. The two constructors exist to accept each of the
/// possible children types - a list of widgets (`children`), or a list of raw
/// [IconData] objects (`iconData`). Because [iconData] objects can be
/// dynamically inserted into [Icon] classes with custom styles, this constructor
/// offers much more helpful default active state handling.
///
/// [RollingNavBar] is a [StatelessWidget] that wraps an internal
/// [StatefulWidget] for the purposes of introducing a [LayoutBuilder] in the
/// render pipeline.
class RollingNavBar extends StatelessWidget {
  /// Optional set of colors for badges while above the active indicator.
  final List<Color> activeBadgeColors;

  /// Optional set of colors of each icon to display when in the active state.
  final List<Color> activeIconColors;

  /// Optional list of badges to apply to each nav item. [null] placeholders
  /// in the list are necessary for unbadged tab bar items.
  final List<Widget> badges;

  /// Initial tab in the highlighted state.
  final int activeIndex;

  /// Behavior of the active indicator's transition from tab to tab.
  final Curve animationCurve;

  /// Indicator for desired animation behavior.
  final AnimationType animationType;

  /// Milliseconds for the background indicator to move one tab.
  final int baseAnimationSpeed;

  /// Optional builder function for the individual navigation icons.
  final RollingNavBarChildBuilder builder;

  /// Optional override for icon colors. If supplied, must have a length of one
  /// or the same length as [iconData]. A length of 1 indicates a single color
  /// for all tabs.
  final List<Color> iconColors;

  /// Icon data to render in the tab bar. Use this option if you want
  /// [RollingNavBar] to manage your tabs' colors. Pass this or [children].
  final List<IconData> iconData;

  /// Optional custom size for each tab bar icon.
  final double iconSize;

  /// Optional list of text widgets to display beneath inactive icons.
  final List<Widget> iconText;

  /// Optional list of colors for the active indicator. If supplied, must have a
  /// length of one or the same length as [iconData]. A length of 1 indicates a
  /// single color for all tabs.
  final List<Color> indicatorColors;

  /// Rounded edge of the active indicator's corners.
  final double indicatorCornerRadius;

  /// Size of the background active indicator.
  final double indicatorRadius;

  /// Number of sides to the background active indicator. Value of `null`
  /// indicates a circle, which negates the rolling effect.
  final int indicatorSides;

  /// Optional display override for the nav bar's background.
  final BoxDecoration navBarDecoration;

  /// Used by the `builder()` constructor to know how many icons the tab bar
  /// should contain.
  final int numChildren;

  /// Optional handler which will be called on every tick of the animation.
  final Function(AnimationUpdate) onAnimate;

  /// Optional handler which is passed every updated active index.
  final Function(int) onTap;

  /// Rotation speed controller with a default value designed to create a
  /// realistic rolling illusion.
  final double sidesPerListItem;

  RollingNavBar.builder({
    @required this.builder,
    @required this.numChildren,
    this.activeBadgeColors,
    this.activeIndex = 0,
    this.animationCurve = Curves.linear,
    this.animationType = AnimationType.roll,
    this.badges,
    this.baseAnimationSpeed = 200,
    this.indicatorColors = const <Color>[Colors.black],
    this.indicatorCornerRadius = 10,
    this.indicatorRadius = 25,
    this.indicatorSides = 6,
    this.navBarDecoration,
    this.onAnimate,
    this.onTap,
    this.sidesPerListItem,
  })  : activeIconColors = null,
        iconColors = null,
        iconData = null,
        iconSize = null,
        iconText = null,
        assert(activeBadgeColors == null ||
            activeBadgeColors.length == 1 ||
            activeBadgeColors.length == numChildren),
        assert(badges == null || badges.length == numChildren),
        assert(indicatorSides > 2),
        assert(numChildren != null);
  RollingNavBar.iconData({
    @required this.iconData,
    this.activeBadgeColors,
    this.activeIconColors,
    this.activeIndex = 0,
    this.animationCurve = Curves.linear,
    this.animationType = AnimationType.roll,
    this.badges,
    this.baseAnimationSpeed = 200,
    this.iconColors = const <Color>[Colors.black],
    this.iconSize,
    this.iconText,
    this.indicatorColors = const <Color>[Colors.pink],
    this.indicatorCornerRadius = 10,
    this.indicatorRadius = 25,
    this.indicatorSides = 6,
    this.navBarDecoration,
    this.onAnimate,
    this.onTap,
    this.sidesPerListItem,
  })  : numChildren = iconData.length,
        builder = null,
        assert(iconText == null || iconText.length == iconData.length),
        assert(indicatorSides > 2),
        assert(activeBadgeColors == null ||
            activeBadgeColors.length == 1 ||
            activeBadgeColors.length == iconData.length),
        assert(activeIconColors == null ||
            activeIconColors.length == 1 ||
            activeIconColors.length == iconData.length),
        assert(badges == null || badges.length == iconData.length),
        assert(iconColors.length == 1 || iconColors.length == iconData.length),
        assert(indicatorColors.length == 1 ||
            indicatorColors.length == iconData.length);

  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return _RollingNavBarInner(
          activeBadgeColors: activeBadgeColors,
          activeIconColors: activeIconColors,
          activeIndex: activeIndex,
          animationCurve: animationCurve,
          animationType: animationType,
          badges: badges,
          baseAnimationSpeed: baseAnimationSpeed,
          builder: builder,
          height: constraints.maxHeight,
          iconColors: iconColors,
          iconData: iconData,
          iconSize: iconSize,
          iconText: iconText,
          indicatorColors: indicatorColors,
          indicatorCornerRadius: indicatorCornerRadius,
          indicatorRadius: indicatorRadius,
          indicatorSides: indicatorSides,
          isLtr: Directionality.of(context).index == 1,
          navBarDecoration: navBarDecoration,
          numChildren: numChildren,
          onAnimate: onAnimate,
          onTap: onTap,
          sidesPerListItem: sidesPerListItem,
          width: constraints.maxWidth,
        );
      },
    );
  }
}

class _RollingNavBarInner extends StatefulWidget {
  final List<Color> activeBadgeColors;
  final List<Color> activeIconColors;
  final int activeIndex;
  final Curve animationCurve;
  final AnimationType animationType;
  final List<Widget> badges;
  final int baseAnimationSpeed;
  final RollingNavBarChildBuilder builder;
  final double height;
  final List<Color> iconColors;
  final List<IconData> iconData;
  final List<Widget> iconText;
  final List<Color> indicatorColors;
  final double indicatorCornerRadius;
  final double indicatorRadius;
  final int indicatorSides;
  final double iconSize;
  final bool isLtr;
  final int numChildren;
  final Function(AnimationUpdate) onAnimate;
  final Function(int) onTap;
  final double sidesPerListItem;
  final BoxDecoration navBarDecoration;
  final double width;
  _RollingNavBarInner({
    @required this.activeBadgeColors,
    @required this.activeIconColors,
    @required this.activeIndex,
    @required this.animationCurve,
    @required this.animationType,
    @required this.badges,
    @required this.baseAnimationSpeed,
    @required this.builder,
    @required this.height,
    @required this.iconColors,
    @required this.iconData,
    @required this.iconSize,
    @required this.iconText,
    @required this.indicatorColors,
    @required this.indicatorCornerRadius,
    @required this.indicatorRadius,
    @required this.indicatorSides,
    @required this.isLtr,
    @required this.numChildren,
    @required this.onAnimate,
    @required this.onTap,
    @required this.sidesPerListItem,
    @required this.navBarDecoration,
    @required this.width,
  });
  @override
  _RollingNavBarInnerState createState() => _RollingNavBarInnerState();
}

class _RollingNavBarInnerState extends State<_RollingNavBarInner>
    with TickerProviderStateMixin {
  // Data needed for any `AnimationType`
  int activeIndex;
  int widgetActiveIndex;
  Color indicatorColor;

  AnimationInfo animationInfo;
  AnimationUpdate animationUpdate;

  // Size-based parameters
  double maxIndicatorRadius;
  double indicatorRadius;

  // Rotation-based parameters
  double indicatorRotation; // in radians
  double indicatorX;
  double sidesPerListItem;

  // Controllers for any `AnimationType`
  AnimationController indicatorAnimationController;
  Animation<double> indicatorAnimationTween;

  @override
  void initState() {
    super.initState();
    widgetActiveIndex = widget.activeIndex;
    activeIndex = widget.activeIndex;
    sidesPerListItem = widget.sidesPerListItem ?? _calculateSidesPerListItem();
    maxIndicatorRadius = widget.indicatorRadius;
    indicatorColor = widget.indicatorColors.length > activeIndex
        ? widget.indicatorColors[activeIndex]
        : widget.indicatorColors.first;
    indicatorRadius = widget.indicatorRadius;
    indicatorRotation = 0;
    indicatorX = activeIndex * tabChunkWidth;
    animationUpdate = initializeAnimationUpdate();
    animationInfo = initializeAnimationInfo();
  }

  AnimationUpdate initializeAnimationUpdate() {
    return AnimationUpdate(
      animationValue: 0,
      rotation: 0,
      percentAnimated: 0,
      direction: Direction.stationary,
      color: _getActiveIconColor(),
    );
  }

  AnimationInfo initializeAnimationInfo() {
    return AnimationInfo(
      startingRotation: 0,
      newIndex: 0,
      oldIndex: 0,
      numSides: widget.indicatorSides,
      sidesPerListItem: sidesPerListItem,
    );
  }

  AnimationUpdate getAnimationCompletedUpdate() {
    return AnimationUpdate(
      animationValue: 1,
      rotation: animationUpdate.rotation,
      percentAnimated: 1,
      direction: Direction.stationary,
      color: _getActiveIconColor(),
    );
  }

  /// Measure of the available space for each nav item.
  double get tabChunkWidth => widget.width / widget.numChildren;

  /// The X coordinate our active indicator needs to reach after each click.
  /// This is only valid *after* updating `activeIndex`.
  double get targetX => activeIndex * tabChunkWidth;

  double _calculateSidesPerListItem() {
    int numChildren = widget.numChildren.clamp(3, 5);
    return <int, double>{
      3: 4,
      4: 3,
      5: 3,
    }[numChildren];
  }

  @override
  void dispose() {
    if (indicatorAnimationController != null)
      indicatorAnimationController.dispose();
    super.dispose();
  }

  void _setActive(int newIndex) {
    if (newIndex == activeIndex) return;
    var _originalIndex = activeIndex;

    // Invoke the optional handler for each tap event.
    if (widget.onTap != null) {
      widget.onTap(newIndex);
    }
    setState(() {
      activeIndex = newIndex;
    });

    animationInfo = AnimationInfo(
      newIndex: newIndex,
      numSides: widget.indicatorSides,
      oldIndex: _originalIndex,
      sidesPerListItem: sidesPerListItem,
      startingRotation: indicatorRotation,
    );

    // Kick off the animation
    if (widget.animationType == AnimationType.roll) {
      _rollActiveIndicator(animationInfo);
    } else if (widget.animationType == AnimationType.snap) {
      _snapActiveIndicator(animationInfo);
    } else if (widget.animationType == AnimationType.spinOutIn) {
      _spinOutInActiveIndicator(animationInfo);
    } else if (widget.animationType == AnimationType.shrinkOutIn) {
      _spinOutInActiveIndicator(animationInfo, shouldRotate: false);
    }
  }

  void _rollActiveIndicator(AnimationInfo info) {
    double _indicatorXAnimationStart = indicatorX;
    indicatorAnimationController = AnimationController(
      duration:
          Duration(milliseconds: widget.baseAnimationSpeed * info.indexDelta),
      vsync: this,
    );
    Animation curve = CurvedAnimation(
        parent: indicatorAnimationController, curve: widget.animationCurve);
    indicatorAnimationTween = Tween<double>(begin: 0, end: 1).animate(curve)
      ..addListener(() {
        if (info.direction == Direction.forward) {
          indicatorRotation =
              info.startingRotation + (info.radiansToRotateDelta * curve.value);
        } else {
          indicatorRotation =
              info.startingRotation - (info.radiansToRotateDelta * curve.value);
        }
        indicatorX = _indicatorXAnimationStart +
            (targetX - _indicatorXAnimationStart) * curve.value;
        indicatorColor = _getRollerColor(
          info.oldIndex,
          info.newIndex,
          curve.value,
        );
        setState(() {});
        if (widget.onAnimate != null) {
          animationUpdate = AnimationUpdate(
            animationValue: curve.value,
            color: indicatorColor,
            direction: info.direction,
            percentAnimated: indicatorAnimationController.value,
            rotation: indicatorRotation,
          );
          widget.onAnimate(animationUpdate);
        }
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          animationUpdate = getAnimationCompletedUpdate();
        }
      });

    indicatorAnimationController.forward();
  }

  void _snapActiveIndicator(AnimationInfo info) {
    setState(() {
      indicatorX = targetX;
      indicatorColor = _getRollerColor(activeIndex, activeIndex, 1.0);
    });
    if (widget.onAnimate != null) {
      animationUpdate = AnimationUpdate(
        animationValue: 1,
        color: indicatorColor,
        direction: info.direction,
        percentAnimated: 1,
        rotation: indicatorRotation,
      );
      widget.onAnimate(animationUpdate);
    }
  }

  void _spinOutInActiveIndicator(AnimationInfo info,
      {bool shouldRotate = true}) {
    indicatorAnimationController = AnimationController(
      duration: Duration(milliseconds: widget.baseAnimationSpeed),
      vsync: this,
    );

    // One rotation to spin out, one to spin in
    double totalRadiansToRotate = 2 * pi * 2;

    Animation curve = CurvedAnimation(
      parent: indicatorAnimationController,
      curve: widget.animationCurve,
    );
    indicatorAnimationTween = Tween<double>(begin: 0, end: 1).animate(curve)
      ..addListener(() {
        if (curve.value < 0.5) {
          double percentToHalf = curve.value * 2;
          indicatorRadius = maxIndicatorRadius * (1 - percentToHalf);
        } else {
          double percentPastHalf = (curve.value - 0.5) * 2;
          indicatorRadius = maxIndicatorRadius * percentPastHalf;
          indicatorX = targetX;
        }
        indicatorColor =
            _getRollerColor(info.oldIndex, info.newIndex, curve.value);
        indicatorRotation = shouldRotate
            ? totalRadiansToRotate * curve.value
            : indicatorRotation;
        setState(() {});

        if (widget.onAnimate != null) {
          animationUpdate = AnimationUpdate(
            animationValue: 1,
            color: indicatorColor,
            direction: info.direction,
            percentAnimated: indicatorAnimationController.value,
            rotation: indicatorRotation,
          );
          widget.onAnimate(animationUpdate);
        }
      });
    indicatorAnimationController.forward();
  }

  Color _getRollerColor(int oldIndex, int newIndex, double animationValue) {
    if (widget.indicatorColors.length == 1) return widget.indicatorColors.first;
    return Color.lerp(
      widget.indicatorColors[oldIndex],
      widget.indicatorColors[newIndex],
      animationValue,
    );
  }

  double get maxWidth =>
      (widget.numChildren - 1) * tabChunkWidth + (tabChunkWidth / 2);

  @override
  Widget build(BuildContext context) {
    double Function(double) directionalityCenterXTransform = widget.isLtr
        ? (x) => x + (tabChunkWidth / 2) - indicatorRadius
        : (x) => maxWidth - x - indicatorRadius;
    return Container(
      height: widget.height,
      decoration: widget.navBarDecoration ??
          BoxDecoration(
            color: Colors.white,
          ),
      child: Stack(
        children: <Widget>[
          ActiveIndicator(
            centerX: directionalityCenterXTransform(indicatorX),
            centerY: (widget.height / 2) - indicatorRadius,
            color: indicatorColor,
            cornerRadius: widget.indicatorCornerRadius,
            height: indicatorRadius * 2,
            numSides: widget.indicatorSides,
            rotation: widget.isLtr ? indicatorRotation : indicatorRotation * -1,
            width: indicatorRadius * 2,
          ),
          Positioned(
            height: widget.height,
            width: widget.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: widget.builder != null
                  ? buildChildren()
                  : indexed(widget.iconData).map(_buildNavBarIcon).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Because `widget.colors` can either have a matching length as the children
  /// count, or simply 1 item which stands for a full list of the same color,
  /// we have to make this check.
  int get colorIndex =>
      widget.indicatorColors.length == widget.numChildren ? activeIndex : 0;

  /// Because `widget.activeIconColors` can either have a matching length as the
  /// children count, or simply 1 item which stands for a full list of the same
  /// color, we have to make this check.
  int get activeIconColorIndex =>
      widget.activeIconColors.length == widget.numChildren ? activeIndex : 0;

  Color _getActiveIconColor() {
    if (widget.activeIconColors == null) {
      return TinyColor(widget.indicatorColors[colorIndex]).lighten(30).color;
    }
    return widget.activeIconColors[activeIconColorIndex];
  }

  Color _getInactiveIconColor(int index) {
    return widget.iconColors.length == widget.numChildren
        ? widget.iconColors[index]
        : widget.iconColors.first;
  }

  Color _getBadgeColor(int index) {
    if (index == activeIndex && widget.activeBadgeColors != null) {
      return widget.activeBadgeColors.length == 1
          ? widget.activeBadgeColors[0]
          : widget.activeBadgeColors[index];
    }

    int inactiveIndex =
        widget.indicatorColors.length >= (index + 1) ? index : 0;
    return activeIndex == index
        ? TinyColor(widget.indicatorColors[colorIndex]).lighten(30).color
        : widget.indicatorColors[inactiveIndex];
  }

  List<Widget> buildChildren() {
    return List<int>.generate(widget.numChildren, (i) => i)
        .map<Widget>(
          (int index) => _buildNavBarItem(
            widget.builder(
              context,
              index,
              animationInfo,
              animationUpdate,
            ),
            Indexed(index, index),
          ),
        )
        .toList();
  }

  Widget _buildNavBarIcon(Indexed indexed) {
    final bool isActive = activeIndex == indexed.index;
    return _buildNavBarItem(
      Icon(
        indexed.value,
        color: isActive
            ? _getActiveIconColor()
            : _getInactiveIconColor(indexed.index),
        size: widget.iconSize,
      ),
      indexed,
    );
  }

  Widget _buildNavBarItem(Widget child, Indexed indexed) {
    final bool isActive = activeIndex == indexed.index;
    return _NavBarItem(
      child,
      badge: widget.badges != null && widget.badges.length >= indexed.index + 1
          ? widget.badges[indexed.index]
          : null,
      badgeColor: _getBadgeColor(indexed.index),
      isActive: isActive,
      height: widget.height,
      key: Key('nav-bar-child-${indexed.index}'),
      maxWidth: tabChunkWidth,
      onPressed: () {
        _setActive(indexed.index);
      },
      textWidget: widget.iconText != null &&
              !isActive &&
              widget.iconText.length == widget.numChildren
          ? widget.iconText[indexed.index]
          : null,
    );
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widgetActiveIndex != widget.activeIndex) {
      setState(() {
        widgetActiveIndex = widget.activeIndex;
        _setActive(widget.activeIndex);
      });
    }
  }
}

/// Foreground widget for each nav bar item.
class _NavBarItem extends StatelessWidget {
  final Widget badge;
  final Color badgeColor;
  final Widget child;
  final bool isActive;
  final double height;
  final Function onPressed;
  final double maxWidth;
  final Widget textWidget;
  const _NavBarItem(
    this.child, {
    @required this.onPressed,
    this.badge,
    this.badgeColor,
    this.isActive = false,
    this.height,
    this.maxWidth,
    this.textWidget,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Reduces rate of missed taps
      onTap: onPressed,
      child: Container(
        height: height,
        width: maxWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _OptionalBadge(
              badge: badge,
              child: child,
              color: badgeColor,
            ),
            textWidget ?? Container(),
          ],
        ),
      ),
    );
  }
}

class _OptionalBadge extends StatelessWidget {
  final Widget badge;
  final Widget child;
  final Color color;
  _OptionalBadge({this.badge, this.child, this.color, Key key})
      : assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return badge != null
        ? Badge(
            badgeColor: color,
            badgeContent: badge,
            child: child,
          )
        : child;
  }
}

/// Colorful indicator for each [_NavBarItem] that animates back and forth
/// across the screen as the user taps.
class ActiveIndicator extends StatelessWidget {
  final double centerX;
  final double centerY;
  final Color color;
  final double cornerRadius;
  final double height;
  final double width;
  final double rotation;
  final int numSides;
  const ActiveIndicator({
    @required this.centerX,
    @required this.centerY,
    @required this.color,
    @required this.cornerRadius,
    @required this.height,
    @required this.width,
    @required this.numSides,
    this.rotation = 0,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: centerY,
      left: centerX,
      height: height,
      width: width,
      child: Transform.rotate(
        angle: rotation,
        child: ClipPolygon(
          sides: numSides,
          borderRadius: cornerRadius,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ),
      ),
    );
  }
}
