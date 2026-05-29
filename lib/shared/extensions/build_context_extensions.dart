import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

extension BuildContextExtensions on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;

  void snackBar(String msg) =>
      ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(msg)));
}
