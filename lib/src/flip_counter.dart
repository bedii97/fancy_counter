import 'dart:math' as math;
import 'dart:ui' show lerpDouble; // For interpolating between two numbers

import 'package:flutter/material.dart';

/// A widget that animates a number by scrolling each digit individually.
///
/// This widget is stateful and uses an [AnimationController] to manually
/// interpolate each digit from its previous value to the new [value].
/// It also supports a synchronized color flash for increases or decreases.
class FlipCounter extends StatefulWidget {
  const FlipCounter({
    super.key,

    // --- Required ---

    /// The target value to animate to.
    required this.value,

    /// The duration of the animation.
    this.duration = const Duration(milliseconds: 300),

    // --- Optional Customization ---

    /// The animation curve to use. Defaults to [Curves.linear]
    /// for a steady, mechanical scroll effect.
    this.curve = Curves.linear,

    /// The [TextStyle] to use for the digits.
    this.style,

    /// An optional text to display before the counter. e.g. `$`
    this.prefix = '',

    /// An optional text to display after the counter. e.g. ` TL`
    this.postfix = '',

    /// The number of digits to display after the decimal point.
    this.fractionDigits = 0,

    /// The color to flash when the value increases. Defaults to [Colors.green].
    this.increaseColor,

    /// The color to flash when the value decreases. Defaults to [Colors.red].
    this.decreaseColor,

    /// Whether to animate the counter on its first build (from 0 to [value]).
    /// Defaults to `true`.
    this.animateOnFirstBuild = true,
  });

  final double value;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final String prefix;
  final String postfix;
  final int fractionDigits;
  final Color? increaseColor;
  final Color? decreaseColor;
  final bool animateOnFirstBuild;

  @override
  _FlipCounterState createState() => _FlipCounterState();
}

class _FlipCounterState extends State<FlipCounter>
    with SingleTickerProviderStateMixin {
  // The main controller for the 0.0 -> 1.0 animation progress.
  late AnimationController _controller;

  // The animation that provides the curved 0.0 -> 1.0 progress.
  late Animation<double> _animation;

  // The animation for the color flash.
  //Changed to double from Color to implement manual TweenSequence logic
  //Otherwise, error occurs when some curves produce values outside 0.0-1.0 range
  late Animation<double> _colorAnimation;

  // State variables to track the animation's start and end points.
  double _previousValue = 0;
  double _currentValue = 0;

  Color _beginColor = Colors.black;
  Color _peakColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Set initial values based on animateOnFirstBuild
    _previousValue = widget.animateOnFirstBuild ? 0.0 : widget.value;
    _currentValue = widget.value;

    _setupAnimations();
    _controller.forward();
  }

  @override
  void didUpdateWidget(FlipCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the target value has changed, restart the animation
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value; // Old value is the one from the widget
      _currentValue = widget.value; // New value is the current widget's value
      _setupAnimations();
      _controller.reset();
      _controller.forward();
    }
  }

  void _setupAnimations() {
    // The main curved animation (0.0 to 1.0)
    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    // This animation will be used to interpolate the value
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);

    _colorAnimation = curvedAnimation;

    // Setup the Color Animation (same logic as AnimatedTextCounter)
    _beginColor = widget.style?.color ?? Colors.black;

    if (_currentValue > _previousValue) {
      _peakColor = widget.increaseColor ?? _beginColor;
    } else if (_currentValue < _previousValue) {
      _peakColor = widget.decreaseColor ?? _beginColor;
    } else {
      _peakColor = _beginColor; // No change
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;

    // AnimatedBuilder listens to the controller for redraws
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

        final effectiveStyle = (widget.style ?? defaultStyle).copyWith(
          color: currentColor,
        );

        // --- 2. Measure a prototype digit for fixed sizing ---
        // This ensures all digit "slots" have the same width,
        // preventing jiggle when '1' changes to '8'.
        final prototypeDigit = TextPainter(
          text: TextSpan(text: '0', style: effectiveStyle),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final Size digitSize = prototypeDigit.size;

        // --- 3. The Core Animation Logic ---

        // Convert previous and current values to strings
        final String previousValueStr = _previousValue.toStringAsFixed(
          widget.fractionDigits,
        );
        final String currentValueStr = _currentValue.toStringAsFixed(
          widget.fractionDigits,
        );

        // Pad strings with leading '0's to ensure equal length
        final int maxLength = math.max(
          previousValueStr.length,
          currentValueStr.length,
        );

        final String prevPadded = previousValueStr.padLeft(maxLength, '0');
        final String currPadded = currentValueStr.padLeft(maxLength, '0');

        final List<Widget> digitWidgets = [];

        for (int i = 0; i < maxLength; i++) {
          final String oldChar = prevPadded[i];
          final String newChar = currPadded[i];

          // If the character is not a digit (e.g., '.', '-'),
          // render it as static text without animation.
          if (int.tryParse(newChar) == null) {
            digitWidgets.add(Text(newChar, style: effectiveStyle));
          } else {
            // If it is a digit...
            final double oldDigit = double.tryParse(oldChar) ?? 0.0;
            final double newDigit = double.tryParse(newChar) ?? 0.0;

            // Calculate the interpolated value for THIS SPECIFIC DIGIT
            // using the main animation's progress (0.0 -> 1.0).
            final double animatedDigitValue = lerpDouble(
              oldDigit,
              newDigit,
              _animation.value, // The 0.0 -> 1.0 progress
            )!;

            // Pass this interpolated value (e.g., 9.5) to the scroll widget.
            digitWidgets.add(
              _SingleDigitScroll(
                value: animatedDigitValue,
                size: digitSize,
                style: effectiveStyle,
              ),
            );
          }
        }

        // --- 4. Build the final Row ---
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.prefix.isNotEmpty)
              Text(widget.prefix, style: effectiveStyle),
            ...digitWidgets, // Insert the list of animated digit widgets
            if (widget.postfix.isNotEmpty)
              Text(widget.postfix, style: effectiveStyle),
          ],
        );
      },
    );
  }
}

/// --- Internal Helper Widget ---

/// A simple [StatelessWidget] that renders a single digit scrolling
/// between two values.
///
/// This widget is "dumb" and simply renders the visual state for a
/// given [value] (e.g., 9.5), which is calculated by its parent.
class _SingleDigitScroll extends StatelessWidget {
  const _SingleDigitScroll({
    required this.value,
    required this.size,
    required this.style,
  });

  /// The interpolated value (e.g., 9.5) to display.
  final double value;

  /// The fixed size for this digit slot, calculated by [TextPainter].
  final Size size;

  /// The [TextStyle] to use for the digits.
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // 1. Calculate the whole and decimal parts of the interpolated value.
    // e.g., value = 9.5 -> whole = 9, decimal = 0.5
    final int whole = value.floor();
    final double decimal = value - whole;

    // 2. Build the Stack for the scroll illusion.
    return SizedBox(
      width: size.width,
      height: size.height,
      child: ClipRect(
        // Prevents digits from scrolling outside the box
        child: Stack(
          children: <Widget>[
            // 3. The "outgoing" (old) digit.
            // e.g., '9'. Fades out (opacity 1.0 -> 0.0)
            // and scrolls up (bottom 0 -> -height).
            Positioned(
              bottom: -decimal * size.height,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 1.0 - decimal,
                child: Text(
                  '${whole % 10}', // '9'
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
            ),

            // 4. The "incoming" (new) digit.
            // e.g., '0' (from 9+1 % 10). Fades in (opacity 0.0 -> 1.0)
            // and scrolls up from the bottom (bottom +height -> 0).
            Positioned(
              bottom: (1 - decimal) * size.height,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: decimal,
                child: Text(
                  '${(whole + 1) % 10}', // '0'
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
