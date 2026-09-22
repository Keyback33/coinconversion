import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../shared/app_failure.dart';
import '../../shared/rate_status.dart';
import '../../shared/widgets/app_brand_mark.dart';
import '../../shared/widgets/section_card.dart';
import '../../theme/app_theme.dart';
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
  Timer? _refreshCountdownTimer;
  bool _manualCooldownWasActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(
      () => ref.read(ratesControllerProvider.notifier).initialize(),
    );
    _refreshCountdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRefreshCountdown(),
    );
  }

  @override
  void dispose() {
    _refreshCountdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _updateRefreshCountdown() {
    if (!mounted) {
      return;
    }
    final availableAt = ref
        .read(ratesControllerProvider)
        .manualRefreshAvailableAtUtc;
    final isActive =
        _manualRefreshRemaining(availableAt, DateTime.now().toUtc()) >
        Duration.zero;
    if (isActive || _manualCooldownWasActive) {
      setState(() => _manualCooldownWasActive = isActive);
    }
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
    final manualRefreshRemaining = _manualRefreshRemaining(
      rates.manualRefreshAvailableAtUtc,
      DateTime.now().toUtc(),
    );
    final manualRefreshCoolingDown = manualRefreshRemaining > Duration.zero;
    final refreshLabel = rates.isRefreshing
        ? 'Refrescando…'
        : manualRefreshCoolingDown
        ? 'Disponible en ${_formatRemaining(manualRefreshRemaining)}'
        : 'Refrescar';
    final compactActions =
        MediaQuery.sizeOf(context).width < 600 ||
        MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppBrandMark(size: 34),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'CoinConversion',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (compactActions)
            IconButton(
              key: const Key('manual-refresh-button'),
              tooltip: refreshLabel,
              onPressed: rates.isRefreshing || manualRefreshCoolingDown
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
            )
          else
            TextButton.icon(
              key: const Key('manual-refresh-button'),
              onPressed: rates.isRefreshing || manualRefreshCoolingDown
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
              label: Text(refreshLabel),
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
            ? Center(
                child: Semantics(
                  label: 'Cargando CoinConversion',
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBrandMark(size: 88),
                      SizedBox(height: 16),
                      CircularProgressIndicator(),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: manualRefreshCoolingDown
                    ? () async {}
                    : () => ref
                          .read(ratesControllerProvider.notifier)
                          .refresh(RefreshTrigger.manual),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _StatusCard(
                      rates: rates,
                      manualRefreshRemaining: manualRefreshRemaining,
                    ),
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
  const _StatusCard({
    required this.rates,
    required this.manualRefreshRemaining,
  });

  final RatesState rates;
  final Duration manualRefreshRemaining;

  @override
  Widget build(BuildContext context) {
    final snapshot = rates.snapshot;
    final sections = Theme.of(context).extension<AppSectionTheme>()!;
    return SectionCard(
      style: sections.status,
      icon: Icons.cloud_sync_outlined,
      title: 'Fuente y estado',
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
              const _Notice(icon: Icons.history, text: 'Cotizaciones antiguas'),
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
          if (manualRefreshRemaining > Duration.zero)
            _Notice(
              icon: Icons.timer_outlined,
              text:
                  'Refresh manual disponible en ${_formatRemaining(manualRefreshRemaining)}.',
            ),
          if (rates.lastRefreshOutcome == RefreshOutcome.noNewer)
            const _Notice(
              icon: Icons.check_circle_outline,
              text: 'No hay cotizaciones más recientes.',
            ),
          if (rates.lastRefreshOutcome == RefreshOutcome.limited &&
              manualRefreshRemaining <= Duration.zero)
            const _Notice(
              icon: Icons.timer_outlined,
              text: 'Esperá antes de volver a actualizar.',
            ),
        ],
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

Duration _manualRefreshRemaining(DateTime? availableAtUtc, DateTime nowUtc) {
  if (availableAtUtc == null || !availableAtUtc.isAfter(nowUtc)) {
    return Duration.zero;
  }
  return availableAtUtc.difference(nowUtc);
}

String _formatRemaining(Duration duration) {
  final totalSeconds = (duration.inMilliseconds + 999) ~/ 1000;
  final hours = totalSeconds ~/ Duration.secondsPerHour;
  final minutes =
      (totalSeconds % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
  final seconds = totalSeconds % Duration.secondsPerMinute;
  if (hours > 0) {
    return '$hours h ${minutes.toString().padLeft(2, '0')} min '
        '${seconds.toString().padLeft(2, '0')} s';
  }
  return '$minutes min ${seconds.toString().padLeft(2, '0')} s';
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
