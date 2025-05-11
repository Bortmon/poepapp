// lib/utils/currency_formatter.dart
import 'package:intl/intl.dart';


String formatCurrencyStandard(double amount)
{
  final formatter = NumberFormat.currency(
    locale: 'nl_NL',
    symbol: '€',
    decimalDigits: 2, 
  );
  return formatter.format(amount);
}

String formatCurrencyLiveTracker(double amount)
{
  final formatter = NumberFormat.currency(
    locale: 'nl_NL',
    symbol: '€',
    decimalDigits: 3,
  );
  return formatter.format(amount);
}