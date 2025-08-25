import 'package:flutter/material.dart';
import 'package:plant_care/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final bool isRegistration;
  
  const AuthScreen({super.key, required this.isRegistration});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _showPassword = false;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

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
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await AuthService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );
      } else {
        await AuthService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    // Dynamic sizing based on screen dimensions
    final iconSize = isVerySmallScreen ? 50.0 : (isSmallScreen ? 60.0 : 70.0);
    final titleSize = isVerySmallScreen ? 20.0 : (isSmallScreen ? 24.0 : 28.0);
    final buttonHeight = isVerySmallScreen ? 44.0 : 48.0;
    final buttonTextSize = isVerySmallScreen ? 13.0 : 14.0;
    final inputTextSize = isVerySmallScreen ? 14.0 : 16.0;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
            ],
          ),
        ),
        child: SafeArea(
          bottom: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: isVerySmallScreen ? 20 : 30,
                  bottom: isVerySmallScreen ? 20 : 30,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (isVerySmallScreen ? 40 : 60),
                    maxHeight: constraints.maxHeight - (isVerySmallScreen ? 40 : 60),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Header section
                        Flexible(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isLogin ? Icons.login : Icons.person_add,
                                size: iconSize,
                                color: Colors.green.shade600,
                              ),
                              SizedBox(height: isVerySmallScreen ? 8 : 10),
                              Text(
                                _isLogin ? 'Welcome Back' : 'Create Account',
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        // Reduced spacing between sections
                        SizedBox(height: isVerySmallScreen ? 8 : 12),
                        
                        // Form section
                        Flexible(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name field (only for registration)
                                  if (!_isLogin) ...[
                                    TextFormField(
                                      controller: _nameController,
                                      style: TextStyle(fontSize: inputTextSize),
                                      decoration: InputDecoration(
                                        labelText: 'Full Name',
                                        prefixIcon: Icon(Icons.person, size: isVerySmallScreen ? 18 : 20),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: isVerySmallScreen ? 10 : 12,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 8 : 12),
                                  ],
                                  
                                  // Email field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(fontSize: inputTextSize),
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email, size: isVerySmallScreen ? 18 : 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: isVerySmallScreen ? 10 : 12,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: isVerySmallScreen ? 8 : 12),
                                  
                                  // Password field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_showPassword,
                                    style: TextStyle(fontSize: inputTextSize),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: Icon(Icons.lock, size: isVerySmallScreen ? 18 : 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _showPassword ? Icons.visibility : Icons.visibility_off,
                                          size: isVerySmallScreen ? 18 : 20,
                                        ),
                                        onPressed: () => setState(() => _showPassword = !_showPassword),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: isVerySmallScreen ? 10 : 12,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  // Remember me checkbox (only for login)
                                  if (_isLogin) ...[
                                    SizedBox(height: isVerySmallScreen ? 8 : 12),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) => setState(() => _rememberMe = value ?? false),
                                        ),
                                        Text(
                                          'Remember me',
                                          style: TextStyle(fontSize: isVerySmallScreen ? 13 : 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                  
                                  SizedBox(height: isVerySmallScreen ? 12 : 16),
                                  
                                  // Submit button
                                  SizedBox(
                                    width: double.infinity,
                                    height: buttonHeight,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: isVerySmallScreen ? 16 : 18,
                                              width: isVerySmallScreen ? 16 : 18,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              _isLogin ? 'Log in' : 'Registration',
                                              style: TextStyle(
                                                fontSize: buttonTextSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Reduced spacing between sections
                        SizedBox(height: isVerySmallScreen ? 8 : 12),
                        
                        // Toggle mode section
                        Flexible(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: isVerySmallScreen ? 8 : 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLogin ? "Don't have an account? " : "Already have an account? ",
                                    style: TextStyle(
                                      fontSize: isVerySmallScreen ? 13 : 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() => _isLogin = !_isLogin),
                                    child: Text(
                                      _isLogin ? 'Registration' : 'Log in',
                                      style: TextStyle(
                                        fontSize: isVerySmallScreen ? 13 : 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 