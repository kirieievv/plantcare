import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/services/auth_service.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_auth_kit.dart';

/// UI from `Botanly /screens/forgot_password_new_password_screen.html`.
/// Logic identical to production: validate length, match, call AuthService,
/// show snackbar, navigate back to login.
class ForgotPasswordNewPasswordScreen extends StatefulWidget {
  final String email;
  final String pin;

  const ForgotPasswordNewPasswordScreen({
    super.key,
    required this.email,
    required this.pin,
  });

  @override
  State<ForgotPasswordNewPasswordScreen> createState() =>
      _ForgotPasswordNewPasswordScreenState();
}

class _ForgotPasswordNewPasswordScreenState
    extends State<ForgotPasswordNewPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final newPassword = _newPasswordController.text;
    final confirm = _confirmController.text;
    if (newPassword.length < 6) {
      setState(() => _error = l10n.passwordAtLeast6);
      return;
    }
    if (newPassword != confirm) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      await AuthService.resetPasswordWithPin(
        email: widget.email,
        pin: widget.pin,
        newPassword: newPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordResetSuccess,
              style: GoogleFonts.dmSans(fontSize: 13)),
          backgroundColor: BotanlyColors.moss,
        ),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
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
            subtitle: l10n.setNewPassword,
          ),
          const SizedBox(height: 40),
          BotanlyAuthField(
            controller: _newPasswordController,
            hint: l10n.newPassword,
            icon: Icons.lock_outline,
            obscure: true,
            showToggleObscure: true,
            autofillHints: AutofillHints.newPassword,
            onChanged: (_) {
              if (_error.isNotEmpty) setState(() => _error = '');
            },
          ),
          const SizedBox(height: 14),
          BotanlyAuthField(
            controller: _confirmController,
            hint: l10n.confirmPassword,
            icon: Icons.lock_outline,
            obscure: true,
            showToggleObscure: true,
            autofillHints: AutofillHints.newPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_isLoading) _resetPassword();
            },
            onChanged: (_) {
              if (_error.isNotEmpty) setState(() => _error = '');
            },
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 16),
            BotanlyAuthErrorBox(message: _error),
          ],
          const SizedBox(height: 28),
          BotanlyAuthPrimaryButton(
            label: l10n.updatePassword,
            loading: _isLoading,
            onPressed: _isLoading ? null : _resetPassword,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
