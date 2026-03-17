import 'package:flutter/material.dart';

class ResponsiveLayout {
  /// Narrow phones (e.g. 320px width) - use smaller padding
  static const double breakpointCompact = 360;
  /// Stack issues/two-column layout vertically below this width
  static const double breakpointStackNarrow = 500;
  /// Stack dashboard stats in column below this width
  static const double breakpointStatsNarrow = 400;
  /// Tablet breakpoint
  static const double breakpointTablet = 600;
  /// Desktop breakpoint
  static const double breakpointDesktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < breakpointTablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointTablet && MediaQuery.of(context).size.width < breakpointDesktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointDesktop;

  /// Horizontal (and optionally full) padding: 16 when narrow (<360), 24 when mobile, 32 when desktop.
  static EdgeInsets getContentPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = w < breakpointCompact ? 16.0 : (w < breakpointTablet ? 24.0 : 32.0);
    return EdgeInsets.all(h);
  }

  static double getCardWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 500;
    return 600;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(16.0);
    if (isTablet(context)) return const EdgeInsets.all(24.0);
    return const EdgeInsets.all(32.0);
  }

  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 800;
    return 1200;
  }

  static Widget responsiveWrapper({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? getMaxContentWidth(context),
        ),
        child: child,
      ),
    );
  }

  static Widget responsiveCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    double? elevation,
  }) {
    return Card(
      elevation: elevation ?? 4,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile(context) ? 8.0 : 16.0,
        vertical: 8.0,
      ),
      child: Padding(
        padding: padding ?? getScreenPadding(context),
        child: child,
      ),
    );
  }
} 