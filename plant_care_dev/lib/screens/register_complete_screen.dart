import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/services/auth_service.dart';
import 'package:plant_care/services/notification_service.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_auth_kit.dart';

/// Step 3 of registration: choose password + confirm password.
/// On success → /home.
class RegisterCompleteScreen extends StatefulWidget {
  final String email;

  const RegisterCompleteScreen({super.key, required this.email});

  @override
  State<RegisterCompleteScreen> createState() => _RegisterCompleteScreenState();
}

class _RegisterCompleteScreenState extends State<RegisterCompleteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _confirmFocusNode = FocusNode();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Sign up without a display name (can be added later in profile)
      await AuthService.signUp(
        email: widget.email,
        password: _passwordController.text,
        name: '',
      );

      await NotificationService().initialize();

      if (mounted) {
        TextInput.finishAutofillContext(shouldSave: true);
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BotanlyAuthScaffold(
      onBack: () => Navigator.of(context).pop(),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BotanlyWordmark(
                title: 'Botanly',
                subtitle: l10n.createYourAccount,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: BotanlyColors.moss.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 32),
              _PasswordField(
                controller: _passwordController,
                hint: l10n.password,
                autofillHints: AutofillHints.newPassword,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _confirmFocusNode.requestFocus(),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.pleaseEnterYourPassword;
                  if (v.length < 6) return l10n.passwordAtLeast6;
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _PasswordField(
                controller: _confirmController,
                focusNode: _confirmFocusNode,
                hint: l10n.confirmPassword,
                autofillHints: AutofillHints.newPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) { if (!_isLoading) _submit(); },
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.pleaseConfirmYourPassword;
                  if (v != _passwordController.text) return l10n.passwordsDoNotMatch;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty) ...[
                BotanlyAuthErrorBox(message: _errorMessage),
                const SizedBox(height: 16),
              ],
              BotanlyAuthPrimaryButton(
                label: l10n.registration,
                loading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final String autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String> validator;

  const _PasswordField({
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    required this.validator,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: !_showPassword,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: [widget.autofillHints],
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: BotanlyColors.moss,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w300,
          color: BotanlyColors.moss.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: Icon(Icons.lock_outline,
              color: BotanlyColors.moss.withValues(alpha: 0.5), size: 20),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: BotanlyColors.moss.withValues(alpha: 0.4),
            size: 20,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(focused: true),
        errorBorder: _border(error: true),
        focusedErrorBorder: _border(error: true, focused: true),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false, bool error = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: error
            ? const Color(0xFFB91C1C)
            : focused
                ? BotanlyColors.moss.withValues(alpha: 0.6)
                : BotanlyColors.moss.withValues(alpha: 0.2),
        width: focused ? 1.5 : 1,
      ),
    );
  }
}
