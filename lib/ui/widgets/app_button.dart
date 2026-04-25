import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
  });

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: variant == AppButtonVariant.primary
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.primary,
        ),
      );
    }
    return Text(label);
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);
    final effectiveOnPressed = isLoading ? null : onPressed;

    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            child: child,
          ),
        );
      case AppButtonVariant.secondary:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: effectiveOnPressed,
            child: child,
          ),
        );
      case AppButtonVariant.text:
        return SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: effectiveOnPressed,
            child: child,
          ),
        );
    }
  }
}
