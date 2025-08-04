import 'package:flutter/material.dart';

enum ButtonType {
  primary,
  secondary, 
  outline,
  text,
}

class CustomButton extends StatelessWidget {
  final String? text;
  final String? label; // Alternative property name used in some places
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    this.text,
    this.label,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.color,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  String get _buttonText => text ?? label ?? '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget buttonChild = _buildButtonContent(context);
    
    if (isLoading) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTextColor(theme),
              ),
            ),
          ),
          if (_buttonText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(_buttonText),
          ],
        ],
      );
    }

    switch (type) {
      case ButtonType.primary:
        return _buildElevatedButton(context, buttonChild);
      case ButtonType.secondary:
        return _buildElevatedButton(context, buttonChild, isSecondary: true);
      case ButtonType.outline:
        return _buildOutlinedButton(context, buttonChild);
      case ButtonType.text:
        return _buildTextButton(context, buttonChild);
    }
  }

  Widget _buildButtonContent(BuildContext context) {
    if (icon != null && _buttonText.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(_buttonText),
        ],
      );
    } else if (icon != null) {
      return Icon(icon, size: 18);
    } else {
      return Text(_buttonText);
    }
  }

  Widget _buildElevatedButton(BuildContext context, Widget child, {bool isSecondary = false}) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? (isSecondary 
            ? theme.colorScheme.secondary 
            : theme.colorScheme.primary),
          foregroundColor: textColor ?? Colors.white,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: child,
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? color ?? theme.colorScheme.primary,
          side: BorderSide(
            color: color ?? theme.colorScheme.primary,
            width: 1.5,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildTextButton(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? 48,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? color ?? theme.colorScheme.primary,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
        child: child,
      ),
    );
  }

  Color _getTextColor(ThemeData theme) {
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        return textColor ?? Colors.white;
      case ButtonType.outline:
      case ButtonType.text:
        return textColor ?? color ?? theme.colorScheme.primary;
    }
  }
} 