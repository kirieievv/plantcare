import 'package:flutter/material.dart';
import 'package:plant_care/screens/auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    // Dynamic sizing based on screen dimensions
    final iconSize = isVerySmallScreen ? 60.0 : (isSmallScreen ? 70.0 : 80.0);
    final titleSize = isVerySmallScreen ? 24.0 : (isSmallScreen ? 28.0 : 32.0);
    final subtitleSize = isVerySmallScreen ? 14.0 : (isSmallScreen ? 16.0 : 18.0);
    final buttonHeight = isVerySmallScreen ? 44.0 : 48.0;
    final buttonTextSize = isVerySmallScreen ? 13.0 : 14.0;
    final descriptionTextSize = isVerySmallScreen ? 12.0 : 14.0;
    
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Top section with icon and title
                        Flexible(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_florist,
                                size: iconSize,
                                color: Colors.green.shade600,
                              ),
                              SizedBox(height: isVerySmallScreen ? 12 : 16),
                              Text(
                                'Plant Care',
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: isVerySmallScreen ? 8 : 12),
                              Text(
                                'Your personal plant care assistant',
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  color: Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        // Middle section with buttons
                        Flexible(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Registration Button
                              SizedBox(
                                width: double.infinity,
                                height: buttonHeight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const AuthScreen(isRegistration: true),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: Text(
                                    'Registration',
                                    style: TextStyle(
                                      fontSize: buttonTextSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isVerySmallScreen ? 8 : 10),
                              
                              // Log in Button
                              SizedBox(
                                width: double.infinity,
                                height: buttonHeight,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const AuthScreen(isRegistration: false),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green.shade600,
                                    side: BorderSide(color: Colors.green.shade600, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Log in',
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
                        
                        // Bottom section with description
                        Flexible(
                          flex: 1,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.eco,
                                  size: isVerySmallScreen ? 20 : 24,
                                  color: Colors.green.shade600,
                                ),
                                SizedBox(height: isVerySmallScreen ? 8 : 12),
                                Text(
                                  'Monitor your plants, get care tips, and track their health with our smart plant care system.',
                                  style: TextStyle(
                                    fontSize: descriptionTextSize,
                                    color: Colors.grey.shade700,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
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
