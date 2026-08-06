import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/theme/botanly_theme.dart';

/// Reusable building blocks for the personal cabinet screens (profile, settings,
/// edit plant, add plant, details, chat) styled per the HTML prototypes in
/// `Botanly /screens/`. Visuals follow the shared design system: white card
/// surfaces (radius 14/20), soft drop shadow, sage accents, Fraunces for
/// section/section-card titles, DM Sans for body and labels.

const Color _shadowColor = Color(0x0D000000);

const List<BoxShadow> botanlyCardShadow = [
  BoxShadow(color: _shadowColor, blurRadius: 10, offset: Offset(0, 4)),
];

class BotanlyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const BotanlyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: botanlyCardShadow,
      ),
      child: child,
    );
  }
}

class BotanlyAvatar extends StatelessWidget {
  final String? letter;
  final double size;
  final IconData? icon;
  const BotanlyAvatar({super.key, this.letter, this.size = 60, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3F1D6), BotanlyColors.sagePale],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: letter != null && letter!.isNotEmpty
          ? Text(
              letter!.substring(0, 1).toUpperCase(),
              style: GoogleFonts.fraunces(
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
                color: BotanlyColors.sage,
              ),
            )
          : Icon(
              icon ?? Icons.person_outline,
              size: size * 0.45,
              color: BotanlyColors.sage,
            ),
    );
  }
}

class BotanlySectionHead extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  const BotanlySectionHead({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE3F1D6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: BotanlyColors.sage),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 16.5,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
              color: BotanlyColors.moss,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class BotanlyEditLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const BotanlyEditLink({
    super.key,
    required this.label,
    this.icon = Icons.edit_outlined,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: BotanlyColors.sage),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: BotanlyColors.sage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BotanlyInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isLast;
  final Widget? valueWidget;
  const BotanlyInfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue =
        (value != null && value!.isNotEmpty) || valueWidget != null;
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFE4EBE1)),
          ),
        ),
        padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8EB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 12, color: BotanlyColors.sage),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.4,
                      color: BotanlyColors.inkMute,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (valueWidget != null)
                    valueWidget!
                  else
                    Text(
                      hasValue ? value! : '—',
                      style: GoogleFonts.dmSans(
                        fontSize: 14.5,
                        fontWeight: hasValue
                            ? FontWeight.w400
                            : FontWeight.w300,
                        fontStyle: hasValue
                            ? FontStyle.normal
                            : FontStyle.italic,
                        height: 1.45,
                        color: hasValue
                            ? const Color(0xFF1B2A18)
                            : BotanlyColors.inkMute,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BotanlyInputShell extends StatelessWidget {
  final IconData icon;
  final Widget child;
  final bool area;
  const BotanlyInputShell({
    super.key,
    required this.icon,
    required this.child,
    this.area = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: area ? 12 : 0),
      constraints: BoxConstraints(minHeight: area ? 0 : 44),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4EBE1), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: area
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: area ? 3 : 0, right: 9),
            child: Icon(icon, size: 15, color: BotanlyColors.sage),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class BotanlyFieldLabel extends StatelessWidget {
  final String label;
  const BotanlyFieldLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: BotanlyColors.inkMute,
        ),
      ),
    );
  }
}

class BotanlyPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;
  final double radius;
  const BotanlyPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.height = 42,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: disabled ? const Color(0xFFCDD5CB) : BotanlyColors.sage,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: disabled ? null : BotanlyShadows.primaryGlow,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: GoogleFonts.dmSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class BotanlySecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  const BotanlySecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF4A5C46),
          side: const BorderSide(color: Color(0xFFE4EBE1), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: const Color(0xFF4A5C46)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A5C46),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared `InputDecoration` for fields wrapped by a Botanly input shell.
/// Disables every default Material border so the outer shell border isn't
/// duplicated by an inner `UnderlineInputBorder` / `OutlineInputBorder`.
InputDecoration botanlyShellInputDecoration({
  String? hint,
  TextStyle? hintStyle,
  EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(vertical: 8),
}) {
  return InputDecoration(
    isCollapsed: true,
    contentPadding: contentPadding,
    filled: false,
    hoverColor: Colors.transparent,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    hintText: hint,
    hintStyle:
        hintStyle ??
        GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: BotanlyColors.inkMute,
        ),
  );
}

/// Pill chip showing user authentication state.
class BotanlyLoggedChip extends StatelessWidget {
  final String label;
  const BotanlyLoggedChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F1D6),
        border: Border.all(color: BotanlyColors.sagePale),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_rounded,
            size: 13,
            color: BotanlyColors.sageDark,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: BotanlyColors.sageDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title rendered above a card (Fraunces, moss).
class BotanlySectionTitle extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  const BotanlySectionTitle(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(4, 4, 4, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: GoogleFonts.fraunces(
          fontSize: 19,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.3,
          color: BotanlyColors.moss,
        ),
      ),
    );
  }
}

class BotanlySettingsRow extends StatelessWidget {
  final IconData? leadingIcon;
  final Color leadingBg;
  final Color leadingFg;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  const BotanlySettingsRow({
    super.key,
    this.leadingIcon,
    this.leadingBg = const Color(0xFFE4EFF8),
    this.leadingFg = BotanlyColors.blue,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: showDivider
                  ? const BorderSide(color: Color(0xFFE4EBE1))
                  : BorderSide.none,
            ),
          ),
          constraints: const BoxConstraints(minHeight: 54),
          child: Row(
            children: [
              if (leadingIcon != null)
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: leadingBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(leadingIcon, size: 16, color: leadingFg),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                        color: const Color(0xFF1B2A18),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          height: 1.4,
                          color: BotanlyColors.inkMute,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// HTML `.switch` toggle — sage track, white knob, 44×26.
class BotanlySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const BotanlySwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: value ? BotanlyColors.sage : const Color(0xFFCDD5CB),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              left: value ? 21 : 3,
              top: 3,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top bar used across cabinet screens — back-button + Fraunces title.
class BotanlyTopBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final List<Widget> actions;
  final VoidCallback? onBack;
  const BotanlyTopBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions = const [],
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          if (showBack)
            _RoundIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 38, height: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
                color: BotanlyColors.moss,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE4EBE1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 16, color: BotanlyColors.moss),
        ),
      ),
    );
  }
}
