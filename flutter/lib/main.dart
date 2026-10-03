import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/discord_auth_service.dart';
import 'features/auth/domain/discord_user.dart';
import 'features/auth/presentation/screens/sign_in_screen.dart';
import 'features/feed/presentation/screens/home_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization skipped for this platform: $e');
  }

  
  final savedUser = await DiscordAuthService.getValidSavedUser();

  runApp(StudyCrowdApp(initialUser: savedUser));
}

class StudyCrowdApp extends StatelessWidget {
  final DiscordUser? initialUser;

  const StudyCrowdApp({
    super.key,
    this.initialUser,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyCrowd',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: initialUser != null
          ? HomeFeedScreen(currentUser: initialUser)
          : const SignInScreen(),
    );
  }
}
