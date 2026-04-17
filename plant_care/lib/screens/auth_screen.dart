import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'main_navigation_screen.dart';
import 'forgot_password_email_screen.dart';

const Color _dark = Color(0xFF1B3A1B);
const Color _mid = Color(0xFF2E6030);

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
  bool _isPasswordVisible = false;
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
      } else {
        final userCredential = await AuthService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
        print('Signup completed successfully for user: ${userCredential.user?.uid}');
      }

      await NotificationService().initialize();

      if (mounted) {
        TextInput.finishAutofillContext(shouldSave: true);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(
              user: FirebaseAuth.instance.currentUser,
              initialIndex: 0,
            ),
          ),
        );
      }
    } catch (e) {
      print('Form submission error: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = '';
    });
  }

  Future<void> _openForgotPasswordFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordEmailScreen()),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.lato(color: _dark.withOpacity(0.6), fontSize: 14),
      prefixIcon: Icon(icon, color: _dark.withOpacity(0.5), size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _dark.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _dark.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _dark.withOpacity(0.6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD6EDD6),
              Color(0xFFF5FAF5),
              Color(0xFFE8F5E8),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back button row
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: _dark.withOpacity(0.7), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Botanly wordmark
                          Center(
                            child: Text(
                              'Botanly',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: _dark,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Screen subtitle
                          Center(
                            child: Text(
                              _isLogin ? l10n.welcomeBack : l10n.createYourAccount,
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                color: _dark.withOpacity(0.55),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Name field (registration only)
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              autofillHints: const [AutofillHints.name],
                              style: GoogleFonts.lato(color: _dark, fontSize: 15),
                              decoration: _fieldDecoration(l10n.fullName, Icons.person_outline),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.pleaseEnterYourName;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                            style: GoogleFonts.lato(color: _dark, fontSize: 15),
                            decoration: _fieldDecoration(l10n.email, Icons.email_outlined),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.pleaseEnterYourEmail;
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return l10n.pleaseEnterValidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            autofillHints: _isLogin
                                ? const [AutofillHints.password]
                                : const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) {
                              if (!_isLoading) _submitForm();
                            },
                            style: GoogleFonts.lato(color: _dark, fontSize: 15),
                            decoration: _fieldDecoration(l10n.password, Icons.lock_outline).copyWith(
                              suffixIcon: Focus(
                                canRequestFocus: false,
                                skipTraversal: true,
                                child: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: _dark.withOpacity(0.4),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                                  },
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.pleaseEnterYourPassword;
                              }
                              if (value.length < 6) {
                                return l10n.passwordAtLeast6;
                              }
                              return null;
                            },
                          ),

                          // Remember me + Forgot password (login only)
                          if (_isLogin) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() => _rememberMe = value ?? true);
                                      },
                                      activeColor: _dark,
                                      side: BorderSide(color: _dark.withOpacity(0.4)),
                                    ),
                                    Text(
                                      l10n.rememberMe30Days,
                                      style: GoogleFonts.lato(
                                        fontSize: 13,
                                        color: _dark.withOpacity(0.65),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _isLoading ? null : _openForgotPasswordFlow,
                                  style: TextButton.styleFrom(
                                    foregroundColor: _dark,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    l10n.forgotPassword,
                                    style: GoogleFonts.lato(
                                      fontSize: 13,
                                      color: _dark.withOpacity(0.65),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Error message
                          if (_errorMessage.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: GoogleFonts.lato(
                                        color: Colors.red.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2E6030), Color(0xFF1B3A1B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _dark.withOpacity(0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.transparent,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? l10n.logIn : l10n.registration,
                                        style: GoogleFonts.lato(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Toggle login/register
                          Center(
                            child: TextButton(
                              onPressed: _isLoading ? null : _toggleMode,
                              style: TextButton.styleFrom(foregroundColor: _dark),
                              child: Text(
                                _isLogin
                                    ? l10n.dontHaveAccountRegistration
                                    : l10n.alreadyHaveAccountLogin,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: _dark.withOpacity(0.65),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
