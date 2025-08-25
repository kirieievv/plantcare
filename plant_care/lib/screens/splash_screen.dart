import 'package:flutter/material.dart';
import 'package:plant_care/screens/auth_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade100,
              Colors.green.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 40,
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Compact top section
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Icon and Title
                          Icon(
                            Icons.local_florist,
                            size: 70,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Plant Care',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your personal plant care assistant',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Compact button section
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Registration Button
                          SizedBox(
                            width: double.infinity,
                            height: 40,
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
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Registration',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          // Log in Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
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
                              child: const Text(
                                'Log in',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Compact description section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade200, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.eco,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Monitor your plants, get care tips, and track their health with our smart plant care system.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Minimal bottom spacing
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
