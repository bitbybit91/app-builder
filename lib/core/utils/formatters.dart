import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String fiat(num amount, String currency) {
    final NumberFormat fmt =
        NumberFormat.currency(symbol: '', decimalDigits: 2);
    return '${fmt.format(amount)} $currency';
  }

  static String crypto(num amount, String coin, {int decimals = 8}) {
    final NumberFormat fmt =
        NumberFormat.decimalPatternDigits(decimalDigits: decimals);
    return '${fmt.format(amount)} $coin';
  }

  static String shortHash(String hash, {int head = 6, int tail = 4}) {
    if (hash.length <= head + tail + 3) return hash;
    return '${hash.substring(0, head)}…${hash.substring(hash.length - tail)}';
  }

  static String dateOnly(DateTime when) =>
      DateFormat.yMMMd().format(when.toLocal());
  static String timeOnly(DateTime when) =>
      DateFormat.Hm().format(when.toLocal());
  static String dateTime(DateTime when) =>
      DateFormat.yMMMd().add_Hm().format(when.toLocal());

  static String timeAgo(DateTime when, {DateTime? now}) {
    final DateTime ref = (now ?? DateTime.now()).toLocal();
    final Duration diff = ref.difference(when.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  static String percent(num value, {int decimals = 1}) =>
      '${value.toStringAsFixed(decimals)}%';
}
