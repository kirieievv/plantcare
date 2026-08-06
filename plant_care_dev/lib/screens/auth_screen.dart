import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'forgot_password_email_screen.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_auth_kit.dart';

/// Auth screen — design from `Botanly /screens/auth_screen.html`.
/// Logic: identical to production (Firebase sign-in/up, autofill, remember-me,
/// forgot password, error handling).
class AuthScreen extends StatefulWidget {
  final bool isRegistration;

  const AuthScreen({super.key, required this.isRegistration});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  late bool _isLogin;
  bool _isLoading = false;
  bool _rememberMe = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _isLogin = !widget.isRegistration;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        await AuthService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );
        await NotificationService().initialize();
        if (mounted) {
          TextInput.finishAutofillContext(shouldSave: true);
          context.go('/home');
        }
      } else {
        // Registration: send PIN and go to verification step
        await AuthService.sendEmailVerificationPin(
          _emailController.text.trim(),
        );
        if (mounted) {
          context.push('/register/verify', extra: _emailController.text.trim());
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(
          () => _errorMessage = switch (e.toString()) {
            'EMAIL_ALREADY_EXISTS' => l10n.errorEmailAlreadyExists,
            'SEND_FAILED' => l10n.errorSendFailed,
            _ => e.toString(),
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = '';
    });
  }

  Future<void> _openForgotPasswordFlow() async {
    context.push('/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BotanlyAuthScaffold(
      onBack: () => context.pop(),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BotanlyWordmark(
                title: 'Botanly',
                subtitle: _isLogin ? l10n.welcomeBack : l10n.createYourAccount,
              ),
              const SizedBox(height: 32),
              _ValidatorField(
                controller: _emailController,
                hint: l10n.email,
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                autofillHints: AutofillHints.email,
                textInputAction: _isLogin
                    ? TextInputAction.next
                    : TextInputAction.done,
                onSubmitted: _isLogin
                    ? (_) => _passwordFocusNode.requestFocus()
                    : (_) {
                        if (!_isLoading) _submitForm();
                      },
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l10n.pleaseEnterYourEmail;
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v)) {
                    return l10n.pleaseEnterValidEmail;
                  }
                  return null;
                },
              ),
              if (_isLogin) ...[
                const SizedBox(height: 14),
                _ValidatorField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  hint: l10n.password,
                  icon: Icons.lock_outline,
                  obscure: true,
                  showToggleObscure: true,
                  autofillHints: AutofillHints.password,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_isLoading) _submitForm();
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.pleaseEnterYourPassword;
                    }
                    if (v.length < 6) return l10n.passwordAtLeast6;
                    return null;
                  },
                ),
              ],
              if (_isLogin) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            _RememberCheckbox(checked: _rememberMe),
                            const SizedBox(width: 8),
                            Text(
                              l10n.rememberMe30Days,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: BotanlyColors.moss.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _openForgotPasswordFlow,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.forgotPassword,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: BotanlyColors.moss.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty) ...[
                BotanlyAuthErrorBox(message: _errorMessage),
                const SizedBox(height: 16),
              ],
              BotanlyAuthPrimaryButton(
                label: _isLogin ? l10n.logIn : l10n.paywallContinue,
                loading: _isLoading,
                onPressed: _isLoading ? null : _submitForm,
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _toggleMode,
                  child: _ToggleLabel(
                    isLogin: _isLogin,
                    text: _isLogin
                        ? l10n.dontHaveAccountRegistration
                        : l10n.alreadyHaveAccountLogin,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Form-aware version of BotanlyAuthField — adds Form validation.
class _ValidatorField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool showToggleObscure;
  final TextInputType keyboardType;
  final String? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String> validator;

  const _ValidatorField({
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.showToggleObscure = false,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    required this.validator,
  });

  @override
  State<_ValidatorField> createState() => _ValidatorFieldState();
}

class _ValidatorFieldState extends State<_ValidatorField> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.obscure && !_showPassword,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints != null
          ? [widget.autofillHints!]
          : null,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: Icon(
            widget.icon,
            color: BotanlyColors.moss.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 20,
        ),
        suffixIcon: widget.showToggleObscure
            ? IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: BotanlyColors.moss.withValues(alpha: 0.4),
                  size: 20,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              )
            : null,
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

class _RememberCheckbox extends StatelessWidget {
  final bool checked;
  const _RememberCheckbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: checked ? BotanlyColors.moss : Colors.transparent,
        border: Border.all(
          color: checked
              ? BotanlyColors.moss
              : BotanlyColors.moss.withValues(alpha: 0.4),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: checked
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}

class _ToggleLabel extends StatelessWidget {
  final bool isLogin;
  final String text;

  const _ToggleLabel({required this.isLogin, required this.text});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w300,
      color: BotanlyColors.moss.withValues(alpha: 0.65),
    );
    final accent = base.copyWith(
      fontWeight: FontWeight.w500,
      color: BotanlyColors.moss,
    );
    final parts = text.split(' ');
    if (parts.length < 2) {
      return Text(text, style: base);
    }
    final lastWord = parts.last;
    final lead = parts.sublist(0, parts.length - 1).join(' ');
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: '$lead ', style: base),
          TextSpan(text: lastWord, style: accent),
        ],
      ),
    );
  }
}
