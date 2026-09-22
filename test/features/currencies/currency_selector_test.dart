import 'package:coinconversion/features/currencies/currency_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre con la lista visible y sin teclado ni búsqueda', (
    tester,
  ) async {
    final sourceFocus = FocusNode();
    addTearDown(sourceFocus.dispose);

    await tester.pumpWidget(_TestApp(sourceFocus: sourceFocus));

    await tester.tap(find.byKey(const Key('source-field')));
    await tester.pump();
    expect(sourceFocus.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('Abrir selector'));
    await tester.pumpAndSettle();

    expect(find.text('Elegir moneda'), findsOneWidget);
    expect(find.text('Buscar código o nombre'), findsNothing);
    expect(find.byTooltip('Buscar monedas'), findsOneWidget);
    expect(find.text('ARS · Peso argentino'), findsOneWidget);
    expect(sourceFocus.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('la lupa abre y cierra la búsqueda sin cerrar el modal', (
    tester,
  ) async {
    final sourceFocus = FocusNode();
    addTearDown(sourceFocus.dispose);

    await tester.pumpWidget(_TestApp(sourceFocus: sourceFocus));
    await tester.tap(find.text('Abrir selector'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Buscar monedas'));
    await tester.pumpAndSettle();

    final searchField = find.widgetWithText(
      TextField,
      'Buscar código o nombre',
    );
    expect(searchField, findsOneWidget);
    expect(find.byTooltip('Cerrar búsqueda'), findsOneWidget);
    expect(tester.widget<TextField>(searchField).focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.enterText(searchField, 'euro');
    await tester.pump();
    expect(find.text('EUR · Euro'), findsOneWidget);
    expect(find.text('ARS · Peso argentino'), findsNothing);

    await tester.tap(find.byTooltip('Cerrar búsqueda'));
    await tester.pumpAndSettle();

    expect(find.text('Elegir moneda'), findsOneWidget);
    expect(find.text('Buscar código o nombre'), findsNothing);
    expect(find.byTooltip('Buscar monedas'), findsOneWidget);
    expect(find.text('ARS · Peso argentino'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byTooltip('Buscar monedas'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('Elegir moneda'), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.sourceFocus});

  final FocusNode sourceFocus;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              TextField(key: const Key('source-field'), focusNode: sourceFocus),
              ElevatedButton(
                onPressed: () =>
                    showCurrencySelector(context, title: 'Elegir moneda'),
                child: const Text('Abrir selector'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
