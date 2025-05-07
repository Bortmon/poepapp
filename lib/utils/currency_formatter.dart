// lib/utils/currency_formatter.dart
import 'package:intl/intl.dart';

String formatCurrency(double amount)
{
  final formatter = NumberFormat.currency(
    locale: 'nl_NL',
    symbol: '€',
    decimalDigits: 3,
  );
  return formatter.format(amount);
}