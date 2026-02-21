extension CurrencyExtension on num {
  String toUsd() => '\$${toStringAsFixed(0)}';
}
