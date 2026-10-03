import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tactile_button.dart';
import '../../../feed/presentation/screens/home_feed_screen.dart';
import '../../data/discord_auth_service.dart';
import '../../domain/discord_user.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback? onSignInWithDiscord;

  const SignInScreen({
    super.key,
    this.onSignInWithDiscord,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isLoading = false;

  Future<void> _handleDiscordSignIn() async {
    if (_isLoading) return;

    if (widget.onSignInWithDiscord != null) {
      widget.onSignInWithDiscord!();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await DiscordAuthService.signInWithDiscord();
      if (!mounted) return;

      if (user != null) {
        _navigateToHomeFeed(user);
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString();
      if (!errorMsg.toLowerCase().contains('cancel')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Discord Sign In: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToHomeFeed(DiscordUser? user) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (context, animation, secondaryAnimation) => HomeFeedScreen(
          currentUser: user,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.04),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 402, // Exact Figma frame width
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Figma Node 39:453 - Hero Illustration
                    Center(
                      child: SizedBox(
                        width: 377,
                        height: 227,
                        child: Image.asset(
                          'assets/images/hero_illustration.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Figma Node 39:466 - "Study\nCrowd." Title
                    Text(
                      'Study\nCrowd.',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.inter(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -2.0,
                        height: 1.0,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Figma Node 39:468 - Subtitle
                    Text(
                      'Crowd Source temporary study spaces.\nLeave with a persistent social network.',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFD9F2E6),
                        height: 1.40,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Figma Node 39:455 - Discord OAuth Button
                    Center(
                      child: TactileButton(
                        onTap: _isLoading ? null : _handleDiscordSignIn,
                        pressedScale: 0.96,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5865F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5865F2).withValues(alpha: 0.42),
                                offset: const Offset(0, 8),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/discord_logo_white.png',
                                        width: 22,
                                        height: 17,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Sign in with Discord',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
