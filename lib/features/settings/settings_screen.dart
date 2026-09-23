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
              title: Text('Tabla general principal'),
              subtitle: Text('ExchangeRate-API · publicación diaria'),
            ),
            const ListTile(
              leading: Icon(Icons.cloud_sync_outlined),
              title: Text('Tabla general alternativa'),
              subtitle: Text(
                'Frankfurter · automática, sin credencial · fechas por par',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.currency_exchange),
              title: Text('MEP principal'),
              subtitle: Text('DolarAPI · dólar MEP venta'),
            ),
            const ListTile(
              leading: Icon(Icons.history),
              title: Text('Respaldo MEP histórico'),
              subtitle: Text('ArgentinaDatos · referencia histórica de venta'),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Peso argentino'),
              subtitle: Text(
                'Los cruces con ARS usan dólar MEP venta como referencia orientativa. No representan un precio operable.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.offline_bolt_outlined),
              title: Text('Funcionamiento offline'),
              subtitle: Text(
                'Después de una descarga exitosa, se usan localmente la última tabla general y el último MEP válidos, con sus fuentes y fechas.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Privacidad'),
              subtitle: Text(
                'Los montos y preferencias no se envían. Los providers reciben consultas de tasas generales USD o de MEP.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.android),
              title: Text('Versión'),
              subtitle: Text('1.0.2 (3)'),
            ),
          ],
        ),
      ),
    );
  }
}
