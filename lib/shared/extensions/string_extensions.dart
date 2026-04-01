extension StringExtensions on String {
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  
  String get truncate => length > 20 ? '${substring(0, 20)}...' : this;
  
  String truncateTo(int maxLength) => length > maxLength ? '${substring(0, maxLength)}...' : this;
  
  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  
  bool get isNumeric => double.tryParse(this) != null;
}
