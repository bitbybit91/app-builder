import 'package:flutter/material.dart';
import 'package:capitalmonero_app/config/app_theme.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  Color? confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: confirmColor != null
              ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}
