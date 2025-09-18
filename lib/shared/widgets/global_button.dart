import 'package:flutter/material.dart';

enum ButtonType { filled, text }

class GlobalButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final IconData? icon;
  final ButtonType type;

  const GlobalButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.isLoading = false,
    this.icon,
    this.type = ButtonType.filled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextColor =
        type == ButtonType.filled ? Colors.white : theme.primaryColor;
    final defaultBackgroundColor =
        type == ButtonType.filled ? theme.primaryColor : Colors.transparent;

    Widget buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(textColor ?? defaultTextColor),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor ?? defaultTextColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: textColor ?? defaultTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );

    if (type == ButtonType.text) {
      return SizedBox(
        width: width,
        height: height ?? 50,
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
            ),
          ),
          child: buttonChild,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? defaultBackgroundColor,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
          ),
        ),
        child: buttonChild,
      ),
    );
  }
}
