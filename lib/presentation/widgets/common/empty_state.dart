import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String? title;
  final String? message;
  final String? description; // Alternative property name
  final IconData? icon;
  final String? lottieAsset;
  final String? animation; // Alternative property name  
  final String? buttonLabel;
  final String? buttonText; // Alternative property name
  final String? actionText; // Alternative property name
  final VoidCallback? onButtonPressed;
  final VoidCallback? onAction; // Alternative property name
  final double? iconSize;
  final Color? iconColor;
  final Widget? customIcon;

  const EmptyState({
    super.key,
    this.title,
    this.message,
    this.description,
    this.icon,
    this.lottieAsset,
    this.animation,
    this.buttonLabel,
    this.buttonText,
    this.actionText,
    this.onButtonPressed,
    this.onAction,
    this.iconSize,
    this.iconColor,
    this.customIcon,
  });

  String get _title => title ?? '';
  String get _message => message ?? description ?? '';
  String get _buttonText => buttonLabel ?? buttonText ?? actionText ?? '';
  VoidCallback? get _onPressed => onButtonPressed ?? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or Animation
            if (customIcon != null)
              customIcon!
            else if (lottieAsset != null || animation != null)
              // For now, show an icon instead of lottie animation
              Icon(
                Icons.sentiment_dissatisfied_outlined,
                size: iconSize ?? 80,
                color: iconColor ?? theme.colorScheme.primary.withOpacity(0.5),
              )
            else
              Icon(
                icon ?? Icons.inbox_outlined,
                size: iconSize ?? 80,
                color: iconColor ?? theme.colorScheme.primary.withOpacity(0.5),
              ),
            
            const SizedBox(height: 24),
            
            // Title
            if (_title.isNotEmpty)
              Text(
                _title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            
            if (_title.isNotEmpty && _message.isNotEmpty)
              const SizedBox(height: 8),
            
            // Message
            if (_message.isNotEmpty)
              Text(
                _message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            
            // Button
            if (_buttonText.isNotEmpty && _onPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
