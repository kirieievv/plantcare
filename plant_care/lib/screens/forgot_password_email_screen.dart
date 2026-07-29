import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/services/auth_service.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_auth_kit.dart';

/// UI from `Botanly /screens/forgot_password_email_screen.html`.
/// Logic identical to production: send PIN via AuthService, push pin screen.
class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState
    extends State<ForgotPasswordEmailScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _error = l10n.pleaseEnterValidEmail);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      await AuthService.requestPasswordResetPin(email);
      if (!mounted) return;
      context.pushReplacement('/forgot-password/pin', extra: email);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _error = switch (e.toString()) {
        'USER_NOT_FOUND' => l10n.errorUserNotFound,
        'INVALID_INPUT' => l10n.pleaseEnterValidEmail,
        'SEND_FAILED' => l10n.errorSendFailed,
        _ => l10n.errorGeneric,
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BotanlyAuthScaffold(
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BotanlyWordmark(
            title: 'Botanly',
            subtitle: l10n.resetYourPassword,
          ),
          const SizedBox(height: 40),
          Text(
            l10n.enterEmailForCode,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              height: 1.55,
              color: BotanlyColors.moss.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 20),
          BotanlyAuthField(
            controller: _emailController,
            hint: l10n.email,
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            autofillHints: AutofillHints.email,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_isLoading) _sendCode();
            },
            onChanged: (_) {
              if (_error.isNotEmpty) setState(() => _error = '');
            },
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            BotanlyAuthErrorBox(message: _error),
          ],
          const SizedBox(height: 28),
          BotanlyAuthPrimaryButton(
            label: l10n.sendCode,
            loading: _isLoading,
            onPressed: _isLoading ? null : _sendCode,
          ),
        ],
      ),
    );
  }
}
