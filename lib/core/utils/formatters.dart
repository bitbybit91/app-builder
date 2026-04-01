import 'package:intl/intl.dart';

class Formatters {
  static String formatCrypto(double amount, {String symbol = 'XMR'}) {
    return '${amount.toStringAsFixed(8)} $symbol';
  }

  static String formatFiat(double amount, {String currency = 'USD'}) {
    final format = NumberFormat.currency(symbol: _getCurrencySymbol(currency));
    return format.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  static String formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  static String _getCurrencySymbol(String currency) {
    const symbols = {
      'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥',
      'CNY': '¥', 'KRW': '₩', 'THB': '฿', 'BRL': 'R\$',
      'SEK': 'kr', 'DKK': 'kr', 'NOK': 'kr',
    };
    return symbols[currency] ?? currency;
  }
}
