import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onReset;

  const ErrorView({super.key, required this.message, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.error.withAlpha(
              (255 * 0.1).round(),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.error,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Oh no!',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.7).round()),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: onReset, child: const Text('Try Again')),
        ],
      ),
    );
  }
}
