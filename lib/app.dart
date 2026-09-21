import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_screen.dart';
import 'providers.dart';

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
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

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
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: preferences.themeMode,
      home: const HomeScreen(),
    );
  }
}
