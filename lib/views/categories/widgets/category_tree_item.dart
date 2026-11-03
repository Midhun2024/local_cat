import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/category_controller.dart';
import '../../../data/models/category_tree_node.dart';
import 'add_category_dialog.dart';

class CategoryTreeItem extends StatelessWidget {
  const CategoryTreeItem({required this.node, super.key});

  final CategoryTreeNode node;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CategoryController>();
    final isExpanded = controller.isExpanded(node.id);
    final isHighlighted = controller.highlightedCategoryId == node.id;
    final theme = Theme.of(context);

    final double indent = node.depth * 20.0;

    return Column(
      key: ValueKey('category_node_${node.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category Row
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isHighlighted
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
                : (node.depth == 0
                      ? theme.colorScheme.surface
                      : theme.colorScheme.surfaceContainerLowest),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHighlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isHighlighted ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 8.0 + indent,
              right: 8.0,
              top: 6.0,
              bottom: 6.0,
            ),
            child: Row(
              children: [
                // Expand / Collapse Icon or Bullet
                if (node.hasChildren)
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => controller.toggleExpanded(node.id),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: isExpanded ? 0.25 : 0.0,
                        child: Icon(
                          Icons.arrow_right,
                          size: 24,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),

                // Folder/tag icon
                Icon(
                  node.depth == 0
                      ? Icons.folder_outlined
                      : Icons.subdirectory_arrow_right,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),

                // Category Name
                Expanded(
                  child: Text(
                    node.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: node.depth == 0
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isHighlighted
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),

                // Children Count Chip
                if (node.hasChildren) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${node.children.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                // Add Subcategory Button
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  tooltip: 'Add subcategory under ${node.name}',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    AddCategoryDialog.show(
                      context: context,
                      parentCategory: node.category,
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Recursive Children
        if (node.hasChildren && isExpanded)
          ...node.children.map(
            (childNode) => CategoryTreeItem(
              key: ValueKey('category_tree_item_${childNode.id}'),
              node: childNode,
            ),
          ),
      ],
    );
  }
}
