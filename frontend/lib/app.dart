import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ndiscord/config/theme.dart';
import 'package:ndiscord/providers/auth_provider.dart';
import 'package:ndiscord/screens/login_screen.dart';
import 'package:ndiscord/screens/home_screen.dart';

class NDiscordApp extends ConsumerWidget {
  const NDiscordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'NDiscord',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authState.isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
