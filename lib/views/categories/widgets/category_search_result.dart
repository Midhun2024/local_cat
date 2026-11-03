import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/category_controller.dart';
import '../../../data/models/category_search_item.dart';

class CategorySearchResult extends StatelessWidget {
  const CategorySearchResult({super.key, required this.item});

  final CategorySearchItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.read<CategoryController>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Name & View in Tree Action
            Row(
              children: [
                Icon(
                  item.category.isRoot
                      ? Icons.folder_outlined
                      : Icons.subdirectory_arrow_right,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.category.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.travel_explore, size: 16),
                  label: const Text('View in Tree'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    controller.navigateToCategoryInTree(item.category.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Full Hierarchy Path Breadcrumbs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.pathString,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Metadata Row: Parent and Children info
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (item.parent != null)
                  Chip(
                    avatar: const Icon(Icons.arrow_upward, size: 14),
                    label: Text('Parent: ${item.parent!.name}'),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  )
                else
                  const Chip(
                    avatar: Icon(Icons.star_outline, size: 14),
                    label: Text('Root Category'),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                if (item.directChildren.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.arrow_downward, size: 14),
                    label: Text(
                      '${item.directChildren.length} direct ${item.directChildren.length == 1 ? 'child' : 'children'}: ${item.directChildren.map((c) => c.name).take(3).join(', ')}${item.directChildren.length > 3 ? '...' : ''}',
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
