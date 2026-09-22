List<String> visibleFavoriteRates(
  List<String> favoriteCodes,
  String referenceCode,
) {
  return favoriteCodes.where((code) => code != referenceCode).toList();
}

List<String> reorderVisibleFavoriteRates({
  required List<String> favoriteCodes,
  required String referenceCode,
  required int oldIndex,
  required int newIndex,
}) {
  final reordered = visibleFavoriteRates(favoriteCodes, referenceCode);
  if (newIndex > oldIndex) {
    newIndex--;
  }
  final value = reordered.removeAt(oldIndex);
  reordered.insert(newIndex, value);
  return _restoreReferencePosition(favoriteCodes, referenceCode, reordered);
}

List<String> moveVisibleFavoriteRate({
  required List<String> favoriteCodes,
  required String referenceCode,
  required int index,
  required int offset,
}) {
  final reordered = visibleFavoriteRates(favoriteCodes, referenceCode);
  final value = reordered.removeAt(index);
  reordered.insert(index + offset, value);
  return _restoreReferencePosition(favoriteCodes, referenceCode, reordered);
}

List<String> _restoreReferencePosition(
  List<String> favoriteCodes,
  String referenceCode,
  List<String> visibleCodes,
) {
  var visibleIndex = 0;
  return [
    for (final code in favoriteCodes)
      if (code == referenceCode) code else visibleCodes[visibleIndex++],
  ];
}
