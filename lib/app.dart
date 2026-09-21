import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_screen.dart';
import 'providers.dart';
import 'theme/app_theme.dart';

class CoinConversionApp extends ConsumerStatefulWidget {
  const CoinConversionApp({super.key});

  @override
  ConsumerState<CoinConversionApp> createState() => _CoinConversionAppState();
}

class _CoinConversionAppState extends ConsumerState<CoinConversionApp> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(preferencesControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesControllerProvider).value;
    return MaterialApp(
      title: 'CoinConversion',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: preferences.themeMode,
      home: const HomeScreen(),
    );
  }
}
