import 'package:coinconversion/features/rates/favorite_rates_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const favorites = ['ARS', 'USD', 'PEN', 'EUR'];

  test('oculta la referencia sin quitarla de favoritos', () {
    expect(visibleFavoriteRates(favorites, 'USD'), ['ARS', 'PEN', 'EUR']);
    expect(favorites, contains('USD'));
  });

  test('reordena monedas visibles y conserva la posición de referencia', () {
    expect(
      reorderVisibleFavoriteRates(
        favoriteCodes: favorites,
        referenceCode: 'USD',
        oldIndex: 0,
        newIndex: 3,
      ),
      ['PEN', 'USD', 'EUR', 'ARS'],
    );
  });

  test('mueve monedas visibles y conserva la posición de referencia', () {
    expect(
      moveVisibleFavoriteRate(
        favoriteCodes: favorites,
        referenceCode: 'USD',
        index: 1,
        offset: -1,
      ),
      ['PEN', 'USD', 'ARS', 'EUR'],
    );
  });
}
