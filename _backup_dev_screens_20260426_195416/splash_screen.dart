import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/botanly_theme.dart';
import 'auth_screen.dart';

/// Matches `Botanly /screens/splash_screen.html` (brand, tagline, buttons, footer copy).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  static const _moss55 = Color(0x8C2D3D2A); // rgba(45,61,42,.55)
  static const _moss45 = Color(0x732D3D2A); // .45 border
  static const _moss75 = Color(0xBF2D3D2A); // .75 text
  static const _moss40 = Color(0x662D3D2A); // .40 description

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BotanlyColors.chromeBg,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 400),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 80),
                              Text(
                                'Botanly',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.fraunces(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w500,
                                  color: BotanlyColors.moss,
                                  letterSpacing: -0.96,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Grow green, live better',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w300,
                                  color: _moss55,
                                  letterSpacing: 0.3,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 64),
                              _primaryButton(context),
                              const SizedBox(height: 14),
                              _secondaryButton(context),
                              const SizedBox(height: 48),
                              Text(
                                'Your personal plant care companion.\n'
                                'Track watering, diagnose issues, and chat with your plants.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  color: _moss40,
                                  height: 1.7,
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
          ),
        ),
      ),
    );
  }

  Widget _primaryButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AuthScreen(isRegistration: true),
          ),
        ),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment(-0.35, -0.9),
              end: Alignment(0.4, 1.1),
              colors: [BotanlyColors.sage, BotanlyColors.moss],
            ),
            boxShadow: BotanlyShadows.splashPrimaryBtn,
          ),
          child: Center(
            child: Text(
              'Get Started',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AuthScreen(isRegistration: false),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _moss75,
          side: BorderSide(color: _moss45, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: Colors.transparent,
        ),
        child: Text(
          'Log In',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            color: _moss75,
          ),
        ),
      ),
    );
  }
}
