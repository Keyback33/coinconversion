import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesControllerProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Tema', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Claro'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Oscuro'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {preferences.themeMode},
              onSelectionChanged: (selection) => ref
                  .read(preferencesControllerProvider.notifier)
                  .update(preferences.copyWith(themeMode: selection.single)),
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.cloud_download_outlined),
              title: Text('Proveedor principal'),
              subtitle: Text('ExchangeRate-API · publicación diaria'),
            ),
            const ListTile(
              leading: Icon(Icons.cloud_sync_outlined),
              title: Text('Fuente alternativa'),
              subtitle: Text('Open Exchange Rates · publicación horaria'),
            ),
            ListTile(
              leading: Icon(
                openExchangeRatesAppId.isEmpty
                    ? Icons.warning_amber
                    : Icons.check_circle_outline,
              ),
              title: const Text('Fallback'),
              subtitle: Text(
                openExchangeRatesAppId.isEmpty
                    ? 'No configurado en este build'
                    : 'Configurado para este build personal',
              ),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Peso argentino'),
              subtitle: Text(
                'ARS es una referencia fiat estándar del provider. No representa dólar blue, MEP, CCL ni un precio operable.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.offline_bolt_outlined),
              title: Text('Funcionamiento offline'),
              subtitle: Text(
                'Después de una descarga exitosa, se usa localmente la última tabla completa conservando su fuente y fechas.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Privacidad'),
              subtitle: Text(
                'Los montos y preferencias no se envían. Los providers reciben solo la consulta de la tabla USD.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.android),
              title: Text('Versión'),
              subtitle: Text('1.0.0 (1)'),
            ),
          ],
        ),
      ),
    );
  }
}
