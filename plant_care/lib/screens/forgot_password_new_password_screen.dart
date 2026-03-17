import 'package:flutter/material.dart';
import 'package:plant_care/services/auth_service.dart';

import 'auth_screen.dart';

class ForgotPasswordNewPasswordScreen extends StatefulWidget {
  final String email;
  final String pin;

  const ForgotPasswordNewPasswordScreen({
    super.key,
    required this.email,
    required this.pin,
  });

  @override
  State<ForgotPasswordNewPasswordScreen> createState() => _ForgotPasswordNewPasswordScreenState();
}

class _ForgotPasswordNewPasswordScreenState extends State<ForgotPasswordNewPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _showNew = false;
  bool _showConfirm = false;
  String _error = '';

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirm = _confirmController.text;
    if (newPassword.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (newPassword != confirm) {
      setState(() => _error = 'Passwords do not match.');
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
        const SnackBar(content: Text('Password reset successfully. Please sign in.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen(isRegistration: false)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set new password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _newPasswordController,
                obscureText: !_showNew,
                decoration: InputDecoration(
                  labelText: 'New password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showNew = !_showNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                obscureText: !_showConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_error, style: TextStyle(color: Colors.red.shade700)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
