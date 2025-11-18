import 'package:flutter/material.dart';

/// A widget that animates text to count up or down to a new [value].
///
/// It also provides an optional color flash animation (e.g., green for
/// increase, red for decrease) perfectly synchronized with the count animation.
class FancyTextCounter extends StatefulWidget {
  /// Creates an [FancyTextCounter] widget.
  const FancyTextCounter({
    super.key,

    // --- Required ---

    /// The target value to animate to.
    required this.value,

    /// The duration of the animation.
    this.duration = const Duration(milliseconds: 300),

    // --- Optional Customization ---

    /// The [TextStyle] to use for the text.
    this.style,

    /// An optional text to display before the counter. e.g. `$`
    this.prefix = '',

    /// An optional text to display after the counter. e.g. ` TL`
    this.postfix = '',

    /// The number of digits to display after the decimal point.
    this.fractionDigits = 0,

    /// The color to flash when the value increases.
    this.increaseColor,

    /// The color to flash when the value decreases.
    this.decreaseColor,

    /// Whether to animate the counter on its first build (from 0 to [value]).
    /// Defaults to `true`.
    this.animateOnFirstBuild = true,

    /// The animation curve to use for both count and color animations.
    /// Defaults to [Curves.easeOut].
    this.curve = Curves.easeOut,
  });

  /// The target value to animate to.
  final double value;

  /// The [Duration] of the animation.
  final Duration duration;

  /// The [TextStyle] to use for the text.
  final TextStyle? style;

  /// An optional text to display before the counter. e.g. `₺`
  final String prefix;

  /// An optional text to display after the counter. e.g. ` USD`
  final String postfix;

  /// The number of digits to display after the decimal point.
  final int fractionDigits;

  /// The color to flash when the value increases.
  final Color? increaseColor;

  /// The color to flash when the value decreases.
  final Color? decreaseColor;

  /// Whether to animate the counter on its first build (from 0 to [value]).
  final bool animateOnFirstBuild;

  /// The animation curve to use for both count and color animations.
  final Curve curve;

  @override
  FancyTextCounterState createState() => FancyTextCounterState();
}

/// The state class for [FancyTextCounter].
class FancyTextCounterState extends State<FancyTextCounter>
    with SingleTickerProviderStateMixin {
  // 1. The main animation controller.
  late AnimationController _controller;

  // 2. The animation for the number value itself.
  late Animation<double> _animation;

  // 3. The animation for the color flash.
  //Changed to double from Color to implement manual TweenSequence logic
  //Otherwise, error occurs when some curves produce values outside 0.0-1.0 range
  late Animation<double> _colorAnimation;

  // 4. Stores the previous value to determine animation direction (increase/decrease).
  double _previousValue = 0;

  Color _beginColor = Colors.black;
  Color _peakColor = Colors.black;

  @override
  void initState() {
    super.initState();
    // 4. Initialize the animation controller.
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Check if the widget should animate on its first build.
    if (!widget.animateOnFirstBuild) {
      _previousValue = widget.value;
    }

    // 5. Set up the animations.
    _setupAnimation(widget.value);

    // 6. Start the animation.
    _controller.forward();
  }

  // This method is called when the parent widget rebuilds with a new [value].
  @override
  void didUpdateWidget(FancyTextCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the target value has changed...
    if (oldWidget.value != widget.value) {
      // 8. Re-setup and restart the animations.
      _setupAnimation(widget.value);
      _controller.reset();
      _controller.forward();
    }
  }

  // Helper method to set up both number and color animations.
  void _setupAnimation(double newValue) {
    // This CurvedAnimation drives both animations, keeping them in sync.
    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // 1. Setup the number animation (Tween from old value to new value).
    _animation = Tween<double>(
      begin: _previousValue,
      end: newValue,
    ).animate(curvedAnimation);

    _colorAnimation = curvedAnimation;

    // 2. Setup the color animation.
    _beginColor = widget.style?.color ?? Colors.black;
    _peakColor; // 'peak' color for the flash

    if (newValue > _previousValue) {
      _peakColor = widget.increaseColor ?? _beginColor;
    } else if (newValue < _previousValue) {
      _peakColor = widget.decreaseColor ?? _beginColor;
    } else {
      _peakColor = _beginColor; // If the value hasn't changed, don't flash.
    }

    // Store the new value as the 'previous value' for the next update.
    _previousValue = newValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 1. Calculate the current color based on the color animation value.
        final double t = _colorAnimation.value;

        // 2.Make sure t is clamped between 0.0 and 1.0 for Color.lerp
        final double clampedT = t.clamp(0.0, 1.0);

        // 3. Calculate the current color based on the color animation value.
        final Color? currentColor;
        if (clampedT < 0.5) {
          // Convert the range 0.0-0.5 to 0.0-1.0
          final double sequenceT = clampedT * 2.0;
          currentColor = Color.lerp(_beginColor, _peakColor, sequenceT);
        } else {
          // Convert the range 0.5-1.0 to 0.0-1.0
          final double sequenceT = (clampedT - 0.5) * 2.0;
          currentColor = Color.lerp(_peakColor, _beginColor, sequenceT);
        }
        return Text(
          '${widget.prefix}'
          '${_animation.value.toStringAsFixed(widget.fractionDigits)}'
          '${widget.postfix}',
          style:
              widget.style?.copyWith(color: currentColor) ??
              TextStyle(color: currentColor),
        );
      },
    );
  }
}
