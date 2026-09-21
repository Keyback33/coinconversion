import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../shared/app_failure.dart';
import '../../shared/rate_status.dart';
import '../converter/converter_panel.dart';
import '../rates/exchange_rate_repository.dart';
import '../rates/rate_metadata.dart';
import '../rates/rates_list.dart';
import '../rates/rates_state.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(
      () => ref.read(ratesControllerProvider.notifier).initialize(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref
          .read(ratesControllerProvider.notifier)
          .refresh(RefreshTrigger.automatic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rates = ref.watch(ratesControllerProvider);
    final preferences = ref.watch(preferencesControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('CoinConversion'),
        actions: [
          TextButton.icon(
            onPressed: rates.isRefreshing
                ? null
                : () => ref
                      .read(ratesControllerProvider.notifier)
                      .refresh(RefreshTrigger.manual),
            icon: rates.isRefreshing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(rates.isRefreshing ? 'Refrescando…' : 'Refrescar'),
          ),
          IconButton(
            tooltip: 'Ajustes',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) => const SettingsScreen(),
              ),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: rates.isLoadingCache
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(ratesControllerProvider.notifier)
                    .refresh(RefreshTrigger.manual),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _StatusCard(rates: rates),
                    if (preferences.saveFailed)
                      const _Notice(
                        icon: Icons.save_outlined,
                        text: 'No se pudo guardar el último cambio.',
                      ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final ratesList = RatesList(snapshot: rates.snapshot);
                        final converter = ConverterPanel(
                          snapshot: rates.snapshot,
                        );
                        if (constraints.maxWidth >= 760) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: ratesList),
                              const SizedBox(width: 12),
                              Expanded(child: converter),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            ratesList,
                            const SizedBox(height: 8),
                            converter,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.rates});

  final RatesState rates;

  @override
  Widget build(BuildContext context) {
    final snapshot = rates.snapshot;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (snapshot == null) ...[
              const Icon(Icons.cloud_off_outlined, size: 40),
              const SizedBox(height: 8),
              Text(
                'Todavía no hay cotizaciones',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'Conectate una vez para descargarlas. Tus monedas y ajustes siguen disponibles.',
                textAlign: TextAlign.center,
              ),
            ] else ...[
              RateMetadata(snapshot: snapshot),
              if (rates.source == RatesSource.cache)
                const _Notice(
                  icon: Icons.offline_bolt_outlined,
                  text: 'Datos guardados',
                ),
              if (RateStatus.isStale(snapshot, DateTime.now().toUtc()))
                const _Notice(
                  icon: Icons.history,
                  text: 'Cotizaciones antiguas',
                ),
              if (RateStatus.isFromFuture(snapshot, DateTime.now().toUtc()))
                const _Notice(
                  icon: Icons.schedule,
                  text: 'Revisá la fecha del dispositivo',
                ),
            ],
            if (rates.refreshFailure != null)
              _Notice(
                icon: Icons.warning_amber,
                text: _failureText(rates.refreshFailure!, snapshot != null),
              ),
            if (rates.cacheReadFailed)
              const _Notice(
                icon: Icons.warning_amber,
                text: 'No se pudieron leer las tasas guardadas.',
              ),
            if (rates.cacheWriteFailed)
              const _Notice(
                icon: Icons.save_outlined,
                text: 'Las tasas se actualizaron, pero no pudieron guardarse.',
              ),
            if (rates.lastRefreshOutcome == RefreshOutcome.noNewer)
              const _Notice(
                icon: Icons.check_circle_outline,
                text: 'No hay cotizaciones más recientes.',
              ),
            if (rates.lastRefreshOutcome == RefreshOutcome.limited)
              const _Notice(
                icon: Icons.timer_outlined,
                text: 'Esperá antes de volver a actualizar.',
              ),
          ],
        ),
      ),
    );
  }

  String _failureText(AppFailure failure, bool hasSnapshot) {
    if (hasSnapshot) {
      return 'No se pudo actualizar; usando datos guardados.';
    }
    return switch (failure.kind) {
      AppFailureKind.timeout => 'La consulta tardó demasiado.',
      AppFailureKind.rateLimited ||
      AppFailureKind.refreshLimited => 'Esperá antes de volver a actualizar.',
      AppFailureKind.serviceUnavailable => 'El servicio no está disponible.',
      AppFailureKind.missingConfiguration || AppFailureKind.authentication =>
        'La fuente alternativa no está disponible.',
      _ => 'No se pudo descargar una cotización válida.',
    };
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
