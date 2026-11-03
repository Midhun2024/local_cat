import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/category_controller.dart';
import '../../core/widgets/app_empty_view.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import 'widgets/add_category_dialog.dart';
import 'widgets/category_search_result.dart';
import 'widgets/category_tree_item.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryController>().loadCategories();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<CategoryController>().search(query);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<CategoryController>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<CategoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        actions: [
          if (!controller.isSearching && controller.treeRoots.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.unfold_more),
              tooltip: 'Expand all',
              onPressed: () => controller.expandAll(),
            ),
            IconButton(
              icon: const Icon(Icons.unfold_less),
              tooltip: 'Collapse all',
              onPressed: () => controller.collapseAll(),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload categories',
            onPressed: () => controller.loadCategories(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Root Category'),
        onPressed: () => AddCategoryDialog.show(context: context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Action Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('[ + Add Category ]'),
                    onPressed: () => AddCategoryDialog.show(context: context),
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(child: _buildContent(context, controller, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CategoryController controller,
    ThemeData theme,
  ) {
    // 1. Initial loading
    if (controller.isLoading && controller.allCategories.isEmpty) {
      return const AppLoadingIndicator(message: 'Loading categories...');
    }

    // 2. Error state
    if (controller.errorMessage != null && controller.allCategories.isEmpty) {
      return AppErrorView(
        message: controller.errorMessage!,
        onRetry: () => controller.loadCategories(),
      );
    }

    // 3. Search Mode
    if (controller.searchQuery.trim().isNotEmpty) {
      return _buildSearchResults(context, controller, theme);
    }

    // 4. Empty state (no categories at all)
    if (controller.isEmpty) {
      return AppEmptyView(
        icon: Icons.account_tree_outlined,
        message: 'No Categories Yet',
        subMessage:
            'Start organizing by adding your first root category using the button below.',
        action: FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Root Category'),
          onPressed: () => AddCategoryDialog.show(context: context),
        ),
      );
    }

    // 5. Hierarchical Tree View
    return RefreshIndicator(
      onRefresh: () => controller.loadCategories(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: controller.treeRoots.length,
        itemBuilder: (context, index) {
          final rootNode = controller.treeRoots[index];
          return CategoryTreeItem(
            key: ValueKey('tree_root_${rootNode.id}'),
            node: rootNode,
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    CategoryController controller,
    ThemeData theme,
  ) {
    if (controller.isSearching) {
      return const AppLoadingIndicator(message: 'Searching categories...');
    }

    final searchResults = controller.searchResults;
    if (searchResults == null || searchResults.isEmpty) {
      return AppEmptyView(
        icon: Icons.search_off,
        message: 'No Categories Found',
        subMessage:
            'No category matching "${controller.searchQuery}" was found anywhere in the hierarchy.',
        action: OutlinedButton(
          onPressed: _clearSearch,
          child: const Text('Clear Search'),
        ),
      );
    }

    return Column(
      children: [
        // Results count banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          child: Row(
            children: [
              Text(
                'Total: ${searchResults.totalCount} | Page Size: ${searchResults.pageSize}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Page ${searchResults.page} of ${searchResults.totalPages}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // List of results
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: searchResults.items.length,
            itemBuilder: (context, index) {
              final item = searchResults.items[index];
              return CategorySearchResult(
                key: ValueKey('search_item_${item.category.id}'),
                item: item,
              );
            },
          ),
        ),

        // Pagination Controls
        if (searchResults.totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Previous'),
                  onPressed: searchResults.hasPreviousPage
                      ? () => controller.search(
                          controller.searchQuery,
                          page: searchResults.page - 1,
                        )
                      : null,
                ),
                Text(
                  '${searchResults.page} / ${searchResults.totalPages}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Next'),
                  onPressed: searchResults.hasNextPage
                      ? () => controller.search(
                          controller.searchQuery,
                          page: searchResults.page + 1,
                        )
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
