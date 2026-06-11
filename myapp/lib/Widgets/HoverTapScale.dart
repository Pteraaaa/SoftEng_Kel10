import 'package:flutter/material.dart';

class HoverTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double hoverScale;
  final double pressScale;
  final bool enabled;

  const HoverTapScale({
    required this.child,
    this.onTap,
    this.borderRadius,
    this.hoverScale = 1.015,
    this.pressScale = 0.985,
    this.enabled = true,
    super.key,
  });

  @override
  State<HoverTapScale> createState() => _HoverTapScaleState();
}

class _HoverTapScaleState extends State<HoverTapScale> {
  bool hovering = false;
  bool pressing = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onTap != null;
    final shouldAnimate = enabled && (hovering || pressing);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: enabled ? (_) => setState(() => hovering = true) : null,
      onExit: enabled
          ? (_) => setState(() {
              hovering = false;
              pressing = false;
            })
          : null,
      child: AnimatedScale(
        scale: pressing
            ? widget.pressScale
            : shouldAnimate
            ? widget.hoverScale
            : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: hovering && enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? widget.onTap : null,
              onTapDown: enabled
                  ? (_) => setState(() => pressing = true)
                  : null,
              onTapUp: enabled ? (_) => setState(() => pressing = false) : null,
              onTapCancel: enabled
                  ? () => setState(() => pressing = false)
                  : null,
              borderRadius: widget.borderRadius,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
