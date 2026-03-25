/// Root application widget — MaterialApp, theme, routing, and providers.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'data/training_repository.dart';
import 'providers/session_controller.dart';
import 'providers/training_list_provider.dart';
import 'screens/active_training_screen.dart';
import 'screens/create_edit_training_screen.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';

/// Top-level application widget.
class SurgeApp extends StatelessWidget {
  const SurgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();
    final repository = TrainingRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TrainingListProvider(repository),
        ),
        ChangeNotifierProvider(
          create: (_) => SessionController(audioService),
        ),
      ],
      child: MaterialApp.router(
        title: 'Surge',
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        routerConfig: _router,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const HomeScreen(),
    ),
    GoRoute(
      path: '/training/new',
      builder: (_, _) => const CreateEditTrainingScreen(),
    ),
    GoRoute(
      path: '/training/:id',
      builder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return CreateEditTrainingScreen(trainingId: id);
      },
    ),
    GoRoute(
      path: '/session',
      builder: (_, _) => const ActiveTrainingScreen(),
    ),
  ],
);

ThemeData _buildTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFF6B35),
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
  );
}
