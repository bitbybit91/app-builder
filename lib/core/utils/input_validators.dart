import '../constants/app_constants.dart';

class InputValidators {
  InputValidators._();

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required';
    if (value.length < 3) return 'Username must be at least 3 characters';
    if (value.length > 32) return 'Username must be at most 32 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Use letters, digits and underscore only';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Add a lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add a digit';
    if (!RegExp(r'''[\W_]''').hasMatch(value)) return 'Add a special character';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, [String name = 'Field']) {
    if (value == null || value.trim().isEmpty) return '$name is required';
    return null;
  }

  static String? amount(String? value, {double min = 0, double? max}) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final double? parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= min) return 'Amount must be greater than $min';
    if (max != null && parsed > max) return 'Amount exceeds limit';
    return null;
  }

  static String? cryptoAddress(String? value, String coin) {
    if (value == null || value.trim().isEmpty) return 'Address is required';
    final String trimmed = value.trim();
    switch (coin.toUpperCase()) {
      case 'XMR':
        if (trimmed.length < 95) return 'Monero address looks too short';
        if (!RegExp(r'^[4|8][1-9A-HJ-NP-Za-km-z]+$').hasMatch(trimmed)) {
          return 'Invalid Monero address';
        }
        return null;
      case 'BTC':
        if (!RegExp(r'^(bc1[0-9a-zA-Z]{6,87}|[13][a-km-zA-HJ-NP-Z1-9]{25,34})$')
            .hasMatch(trimmed)) {
          return 'Invalid Bitcoin address';
        }
        return null;
      default:
        return 'Unsupported coin';
    }
  }

  static String? totp(String? value) {
    if (value == null || value.isEmpty) return 'Enter a 2FA code';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) return 'Code must be 6 digits';
    return null;
  }

  static String? percentage(String? value, {double min = -50, double max = 50}) {
    if (value == null || value.trim().isEmpty) return 'Percentage is required';
    final double? parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return 'Enter a valid number';
    if (parsed < min || parsed > max) return 'Must be between $min% and $max%';
    return null;
  }

  static String? mnemonic(String? value) {
    if (value == null || value.trim().isEmpty) return 'Mnemonic is required';
    final List<String> words = value.trim().toLowerCase().split(RegExp(r'\s+'));
    if (words.length != 12 && words.length != 24) {
      return 'Mnemonic must contain 12 or 24 words';
    }
    return null;
  }
}
