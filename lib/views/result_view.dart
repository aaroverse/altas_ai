import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../widgets/menu_item_card.dart';

class ResultView extends StatelessWidget {
  final List<MenuItem> items;
  final VoidCallback onReset;

  const ResultView({super.key, required this.items, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16), // Increase top margin
        Text(
          'Here\'s your menu',
          style: theme.textTheme.displaySmall,
        ), // h1, text-4xl font-bold
        const SizedBox(height: 8),
        Text(
          'We\'ve translated and analyzed the dishes for you.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha((255 * 0.7).round()),
          ), // p, text-lg text-subtle-light
        ),
        const SizedBox(height: 32), // mb-8
        // List of menu items
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            padding: const EdgeInsets.only(
              bottom: 80,
            ), // Padding for FAB not to overlap content
            separatorBuilder: (context, index) =>
                const SizedBox(height: 10), // Reduce margin between cards
            itemBuilder: (context, index) {
              return MenuItemCard(item: items[index]);
            },
          ),
        ),
      ],
    );
  }
}
