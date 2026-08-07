import 'package:flutter/material.dart';

// ─────────────────── Shimmer animation ───────────────────

/// Soft shimmer highlight that sweeps left-to-right.
/// Wrap any skeleton placeholder with this to give it the loading effect.
class BotanlyShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const BotanlyShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<BotanlyShimmer> createState() => _BotanlyShimmerState();
}

class _BotanlyShimmerState extends State<BotanlyShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFEAEFE7), // base
                Color(0xFFF5F8F3), // highlight
                Color(0xFFEAEFE7), // base
              ],
              stops: [
                (_ctrl.value - 0.3).clamp(0.0, 1.0),
                _ctrl.value,
                (_ctrl.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────── Shape helpers ───────────────────

/// Shimmer placeholder shapes.
class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFE7),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ShimmerPill extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerPill({super.key, this.width = 72, this.height = 30});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFE7),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFE7),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFEAEFE7),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────── Plant tile skeleton ───────────────────

/// Skeleton for a single BotanlyPlantTile row (thumb + name + status + water btn).
class ShimmerPlantTile extends StatelessWidget {
  const ShimmerPlantTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          // Accent bar
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEFE7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          // Thumb
          const ShimmerBox(width: 62, height: 62, radius: 14),
          const SizedBox(width: 14),
          // Text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                ShimmerLine(width: 120, height: 15),
                SizedBox(height: 8),
                ShimmerPill(width: 80, height: 22),
              ],
            ),
          ),
          // Water button placeholder
          const ShimmerCircle(size: 36),
        ],
      ),
    );
  }
}

// ─────────────────── Stat card skeleton ───────────────────

/// Skeleton for a single dashboard stat card (icon + number + label).
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          ShimmerCircle(size: 28),
          SizedBox(height: 8),
          ShimmerLine(width: 36, height: 18),
          SizedBox(height: 6),
          ShimmerLine(width: 56, height: 11),
        ],
      ),
    );
  }
}

// ─────────────────── Banner skeleton ───────────────────

/// Skeleton for the dashboard banner carousel.
class ShimmerBanner extends StatelessWidget {
  const ShimmerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ShimmerBox(height: 80, radius: 18),
    );
  }
}

// ─────────────────── Profile header skeleton ───────────────────

/// Skeleton matching the profile header card (avatar + name + email + sub chip).
class ShimmerProfileHeader extends StatelessWidget {
  const ShimmerProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const ShimmerCircle(size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerLine(width: 130, height: 18),
                    SizedBox(height: 8),
                    ShimmerLine(width: 170, height: 13),
                    SizedBox(height: 6),
                    ShimmerLine(width: 100, height: 11),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const ShimmerBox(height: 38, radius: 12),
        ],
      ),
    );
  }
}

// ─────────────────── Info card skeleton ───────────────────

/// Skeleton for a BotanlyCard with n info rows (label + value).
class ShimmerInfoCard extends StatelessWidget {
  final int rows;
  const ShimmerInfoCard({super.key, this.rows = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header placeholder
          Row(
            children: const [
              ShimmerCircle(size: 28),
              SizedBox(width: 10),
              ShimmerLine(width: 110, height: 15),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(
            rows,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLine(width: 80, height: 11),
                  const SizedBox(height: 5),
                  ShimmerLine(width: i % 2 == 0 ? 160 : 120, height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── Tip card skeleton ───────────────────

/// Skeleton for a single _TipCard on the Tips screen.
class ShimmerTipCard extends StatelessWidget {
  const ShimmerTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEBEB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              ShimmerBox(width: 40, height: 40, radius: 12),
              SizedBox(width: 12),
              ShimmerPill(width: 70, height: 22),
              Spacer(),
              ShimmerCircle(size: 28),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerLine(height: 13),
          const SizedBox(height: 7),
          const ShimmerLine(height: 13),
          const SizedBox(height: 7),
          ShimmerLine(width: 200, height: 13),
        ],
      ),
    );
  }
}

// ─────────────────── Chat bubble skeleton ───────────────────

/// Skeleton for a short history of chat messages (alternating left/right bubbles).
class ShimmerChatHistory extends StatelessWidget {
  const ShimmerChatHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: const [
          _ShimmerBubble(isUser: false, width: 220),
          SizedBox(height: 10),
          _ShimmerBubble(isUser: true, width: 160),
          SizedBox(height: 10),
          _ShimmerBubble(isUser: false, width: 260),
          SizedBox(height: 10),
          _ShimmerBubble(isUser: true, width: 140),
        ],
      ),
    );
  }
}

class _ShimmerBubble extends StatelessWidget {
  final bool isUser;
  final double width;
  const _ShimmerBubble({required this.isUser, required this.width});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: width,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFEAEFE7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Health check history skeleton ───────────────────

/// Skeleton for the health check history list on Plant Details.
class ShimmerHealthHistory extends StatelessWidget {
  const ShimmerHealthHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBEBEB)),
            ),
            child: Row(
              children: const [
                ShimmerBox(width: 58, height: 58, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLine(width: 80, height: 11),
                      SizedBox(height: 7),
                      ShimmerLine(height: 13),
                      SizedBox(height: 6),
                      ShimmerLine(width: 140, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Skeleton row (settings-like) ───────────────────

/// A single settings-row skeleton: title line + subtitle line + trailing pill.
class ShimmerSettingsRow extends StatelessWidget {
  final bool showTrailing;
  final bool showDivider;

  const ShimmerSettingsRow({
    super.key,
    this.showTrailing = true,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLine(
                      width: 120 + (showTrailing ? 0 : 40),
                      height: 13,
                    ),
                    const SizedBox(height: 7),
                    ShimmerLine(
                      width: 180 + (showTrailing ? 0 : 20),
                      height: 11,
                    ),
                  ],
                ),
              ),
              if (showTrailing) const ShimmerPill(width: 48, height: 28),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFF0F3ED)),
      ],
    );
  }
}

// ─────────────────── DelayedSkeleton ───────────────────

/// Shows [skeleton] only if [loaded] stays false for longer than [delay].
/// When [loaded] becomes true, cross-fades to [child] with staggered entrance.
class DelayedSkeleton extends StatefulWidget {
  final bool loaded;
  final Widget skeleton;
  final Widget child;
  final Duration delay;
  final Duration fadeDuration;

  const DelayedSkeleton({
    super.key,
    required this.loaded,
    required this.skeleton,
    required this.child,
    this.delay = const Duration(milliseconds: 300),
    this.fadeDuration = const Duration(milliseconds: 280),
  });

  @override
  State<DelayedSkeleton> createState() => _DelayedSkeletonState();
}

class _DelayedSkeletonState extends State<DelayedSkeleton> {
  bool _showSkeleton = false;
  bool _delayPassed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.loaded) {
      Future.delayed(widget.delay, () {
        if (mounted && !widget.loaded) {
          setState(() {
            _showSkeleton = true;
            _delayPassed = true;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant DelayedSkeleton old) {
    super.didUpdateWidget(old);
    if (widget.loaded && !old.loaded) {
      _showSkeleton = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loaded) {
      if (_delayPassed) {
        return AnimatedSwitcher(
          duration: widget.fadeDuration,
          child: widget.child,
        );
      }
      return widget.child;
    }
    if (_showSkeleton) {
      return widget.skeleton;
    }
    return const SizedBox.shrink();
  }
}

// ─────────────────── Staggered fade-up ───────────────────

/// Wraps a child with a staggered fade + slide-up entrance.
/// Use [index] to offset the animation start (50 ms per step).
class StaggeredFadeUp extends StatefulWidget {
  final int index;
  final bool show;
  final Widget child;
  final Duration stagger;
  final Duration duration;

  const StaggeredFadeUp({
    super.key,
    required this.index,
    required this.show,
    required this.child,
    this.stagger = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 260),
  });

  @override
  State<StaggeredFadeUp> createState() => _StaggeredFadeUpState();
}

class _StaggeredFadeUpState extends State<StaggeredFadeUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.show) _scheduleReveal();
  }

  void _scheduleReveal() {
    if (_triggered) return;
    _triggered = true;
    final delay = widget.stagger * widget.index;
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(covariant StaggeredFadeUp old) {
    super.didUpdateWidget(old);
    if (widget.show && !old.show) _scheduleReveal();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && !_triggered) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
