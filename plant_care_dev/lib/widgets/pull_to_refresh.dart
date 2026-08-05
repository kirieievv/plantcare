/// Pull to refresh — the gesture that replaced the refresh button.
///
/// Deliberately not [RefreshIndicator]: the handoff specifies its own numbers
/// (64 px trigger, 112 px ceiling, resistance that stiffens past the threshold)
/// and its own indicator, and the loading animation lives inside the garden
/// ring rather than in a spinner at the top.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pulled distance at which releasing fires the refresh.
const kPullThreshold = 64.0;

/// The gesture stops travelling here — past this there is nothing to gain.
const kPullMax = 112.0;

class BotanlyPullToRefresh extends StatefulWidget {
  /// Watched so the gesture only starts at the very top of the list.
  final ScrollController controller;

  /// 0 → 1 as the pull reaches the threshold. Handed to the ring so its clouds
  /// roll in with the finger; kept as a notifier so a pull repaints the
  /// animation and nothing else.
  final ValueNotifier<double> progress;

  /// A request is already out: the gesture is inert and no second one is sent.
  final bool busy;

  final VoidCallback onRefresh;

  final Widget child;

  const BotanlyPullToRefresh({
    super.key,
    required this.controller,
    required this.progress,
    required this.busy,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<BotanlyPullToRefresh> createState() => _BotanlyPullToRefreshState();
}

class _BotanlyPullToRefreshState extends State<BotanlyPullToRefresh>
    with SingleTickerProviderStateMixin {
  final _pull = ValueNotifier<double>(0);

  late final AnimationController _settle;
  Animation<double>? _settleTween;

  bool _dragging = false;
  double _startY = 0;

  /// True from the moment the pull crosses the threshold until it falls back
  /// under it. Without this flag a finger resting on 64 px would buzz on every
  /// pixel of tremor (§4.1).
  bool _crossed = false;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() => _setPull(_settleTween?.value ?? 0));
  }

  @override
  void dispose() {
    _settle.dispose();
    _pull.dispose();
    super.dispose();
  }

  void _setPull(double value) {
    _pull.value = value;
    widget.progress.value = (value / kPullThreshold).clamp(0.0, 1.0);
  }

  bool get _atTop =>
      !widget.controller.hasClients || widget.controller.offset <= 1;

  void _onDown(PointerDownEvent e) {
    if (widget.busy || !_atTop) return;
    _settle.stop();
    _dragging = true;
    _startY = e.position.dy;
    _crossed = false;
  }

  void _onMove(PointerMoveEvent e) {
    if (!_dragging) return;

    final dy = e.position.dy - _startY;
    // Pulled back above where the finger started: drop the gesture flat, with
    // no spring, so it does not read as a rejected pull.
    if (dy <= 0) {
      if (_pull.value != 0) _setPull(0);
      _crossed = false;
      return;
    }
    if (!_atTop) {
      _dragging = false;
      _setPull(0);
      return;
    }

    // Resistance stiffens past the threshold — the "stop" the finger feels.
    final travelled = (dy * (dy > kPullThreshold ? 0.55 : 0.8)).clamp(
      0.0,
      kPullMax,
    );
    _setPull(travelled);

    if (travelled >= kPullThreshold && !_crossed) {
      _crossed = true;
      HapticFeedback.lightImpact();
    } else if (travelled < kPullThreshold) {
      // Crossing back does not buzz: only entering the zone does (§4.2).
      _crossed = false;
    }
  }

  void _onRelease([PointerEvent? _]) {
    if (!_dragging) return;
    _dragging = false;

    final fired = _pull.value >= kPullThreshold;
    _crossed = false;

    if (fired) {
      HapticFeedback.mediumImpact();
      widget.onRefresh();
    }
    _springBack();
  }

  void _springBack() {
    _settleTween = Tween<double>(begin: _pull.value, end: 0).animate(
      CurvedAnimation(parent: _settle, curve: const Cubic(0.22, 1, 0.36, 1)),
    );
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onRelease,
      onPointerCancel: _onRelease,
      child: Stack(
        children: [
          // The content follows the finger at half speed: enough to feel
          // attached to the gesture, not enough to shove the ring off screen.
          AnimatedBuilder(
            animation: _pull,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _pull.value * 0.5),
              child: child,
            ),
            child: widget.child,
          ),
          _rail(),
        ],
      ),
    );
  }

  /// 2 px at the very top edge, filling left to right with the pull. It stays
  /// full while the request is out, so the screen is never silent about it.
  Widget _rail() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 2,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([_pull, widget.progress]),
          builder: (_, __) {
            final p = widget.busy
                ? 1.0
                : (_pull.value / kPullThreshold).clamp(0.0, 1.0);
            if (p == 0) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: p,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3E8E3B), Color(0xFF8DF0FF)],
                    ),
                  ),
                  child: SizedBox(height: 2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Haptics for the two ends of the request, kept next to the gesture that
/// starts it. Android gets neither: its success pattern is coarse enough that
/// the handoff drops it (§4.6).
void refreshSuccessHaptic() {
  if (_isIOS) HapticFeedback.selectionClick();
}

void refreshErrorHaptic() {
  if (_isIOS) HapticFeedback.heavyImpact();
}

bool get _isIOS => !kIsWeb && Platform.isIOS;

/// Kills the Android overscroll glow: the rail is the only pull feedback.
class NoGlowScrollBehavior extends MaterialScrollBehavior {
  const NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
