import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/theme.dart';

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.child,
    this.safeArea = true,
  });

  final Widget child;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final body = Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF5FFFD),
                Color(0xFFE6F7F3),
                Color(0xFFFDF7F0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: isCompact ? -60 : -80,
          left: isCompact ? -30 : -40,
          child: _GlowOrb(
            size: isCompact ? 160 : 220,
            color: AppTheme.primaryLight.withValues(alpha: 0.28),
          ),
        ),
        Positioned(
          top: isCompact ? 70 : 90,
          right: isCompact ? -20 : -30,
          child: _GlowOrb(
            size: isCompact ? 130 : 180,
            color: AppTheme.accentColor.withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          bottom: isCompact ? -50 : -70,
          right: isCompact ? -10 : -20,
          child: _GlowOrb(
            size: isCompact ? 180 : 240,
            color: AppTheme.primaryColor.withValues(alpha: 0.14),
          ),
        ),
        if (safeArea) SafeArea(child: child) else child,
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
    );
  }
}

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1120,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final horizontalPadding = constraints.maxWidth > 720
            ? 28.0
            : isCompact
                ? 14.0
                : padding.horizontal / 2;
        return SizedBox.expand(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              padding.top,
              horizontalPadding,
              padding.bottom,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final resolvedPadding = isCompact ? const EdgeInsets.all(14) : padding;
    final resolvedRadius = isCompact ? radius - 4 : radius;
    return ClipRRect(
      borderRadius: BorderRadius.circular(resolvedRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: resolvedPadding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(resolvedRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class AnimatedEntrance extends StatefulWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 24,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * widget.offsetY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;
    final isNarrowPhone = width < 420;
    final defaultLeading = leading ??
        Container(
          height: isCompact ? 48 : 56,
          width: isCompact ? 48 : 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isCompact ? 22 : 28,
          ),
        );

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: isNarrowPhone ? 4 : null,
          overflow: TextOverflow.visible,
          style: AppTheme.headingMedium.copyWith(
            color: Colors.white,
            fontSize: isNarrowPhone
                ? 17
                : isCompact
                    ? 19
                    : AppTheme.headingMedium.fontSize,
            height: isNarrowPhone ? 1.15 : null,
          ),
        ),
        SizedBox(height: isCompact ? 6 : 8),
        Text(
          subtitle,
          style: AppTheme.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.86),
            fontSize: isNarrowPhone ? 12 : null,
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isCompact ? 18 : 24),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(isCompact ? 24 : 32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.18),
            blurRadius: isCompact ? 22 : 30,
            offset: Offset(0, isCompact ? 12 : 16),
          ),
        ],
      ),
      child: isNarrowPhone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    defaultLeading,
                    if (trailing != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: trailing!,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                textBlock,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                defaultLeading,
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(child: textBlock),
                if (trailing != null) ...[
                  SizedBox(width: isCompact ? 8 : 12),
                  Flexible(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: trailing!,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    super.key,
    this.size = 72,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(10),
    this.borderRadius = 24,
  });

  final double size;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Image.asset(
        'assets/images/app_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isCompact ? 12 : 14, color: color),
            SizedBox(width: isCompact ? 4 : 6),
          ],
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
