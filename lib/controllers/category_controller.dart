import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/models/category_model.dart';
import '../data/models/category_search_item.dart';
import '../data/models/category_tree_node.dart';
import '../data/models/paginated_result.dart';
import '../data/repositories/category_repository.dart';

class CategoryController extends ChangeNotifier {
  CategoryController({required this.categoryRepository});

  final CategoryRepository categoryRepository;

  List<CategoryModel> _allCategories = [];
  List<CategoryTreeNode> _treeRoots = [];
  final Set<int> _expandedNodeIds = {};

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Search & Pagination state
  String _searchQuery = '';
  PaginatedResult<CategorySearchItem>? _searchResults;
  bool _isSearching = false;
  int _searchPage = 1;
  int _searchPageSize = 10;
  int? _highlightedCategoryId;

  bool _isDisposed = false;

  // Getters
  List<CategoryModel> get allCategories => List.unmodifiable(_allCategories);
  List<CategoryTreeNode> get treeRoots => List.unmodifiable(_treeRoots);
  Set<int> get expandedNodeIds => Set.unmodifiable(_expandedNodeIds);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  PaginatedResult<CategorySearchItem>? get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  int get searchPage => _searchPage;
  int get searchPageSize => _searchPageSize;
  int? get highlightedCategoryId => _highlightedCategoryId;
  bool get isEmpty => _allCategories.isEmpty;

  bool isExpanded(int categoryId) => _expandedNodeIds.contains(categoryId);

  /// Loads all categories and builds the category tree.
  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _allCategories = await categoryRepository.getAllCategories();
      _treeRoots = CategoryTreeHelper.buildTree(_allCategories);
      _isLoading = false;
      _safeNotifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load categories.';
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Toggles expansion state of a specific category tree node.
  void toggleExpanded(int categoryId) {
    if (_expandedNodeIds.contains(categoryId)) {
      _expandedNodeIds.remove(categoryId);
    } else {
      _expandedNodeIds.add(categoryId);
    }
    _safeNotifyListeners();
  }

  /// Expands all nodes in the tree.
  void expandAll() {
    _expandedNodeIds.addAll(_allCategories.map((c) => c.id));
    _safeNotifyListeners();
  }

  /// Collapses all nodes in the tree.
  void collapseAll() {
    _expandedNodeIds.clear();
    _safeNotifyListeners();
  }

  /// Creates a new root or subcategory.
  Future<bool> createCategory({required String name, int? parentId}) async {
    _isSaving = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final newCategory = await categoryRepository.createCategory(
        name: name,
        parentId: parentId,
      );

      // Refresh the category list from repository
      _allCategories = await categoryRepository.getAllCategories();
      _treeRoots = CategoryTreeHelper.buildTree(_allCategories);

      // Auto-expand parent so new child is visible
      if (parentId != null) {
        _expandedNodeIds.add(parentId);
      }
      _highlightedCategoryId = newCategory.id;

      _isSaving = false;
      _safeNotifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isSaving = false;
      _safeNotifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to save category.';
      _isSaving = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// Executes search across entire hierarchy with pagination.
  Future<void> search(
    String query, {
    int page = 1,
    int? pageSize,
    int? limit,
  }) async {
    _searchQuery = query;
    _searchPage = page;
    if (pageSize != null) _searchPageSize = pageSize;

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _searchResults = null;
      _isSearching = false;
      _safeNotifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _searchResults = await categoryRepository.searchCategories(
        query: trimmed,
        page: _searchPage,
        pageSize: _searchPageSize,
        limit: limit,
      );
      _isSearching = false;
      _safeNotifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isSearching = false;
      _safeNotifyListeners();
    } catch (e) {
      _errorMessage = 'Search failed.';
      _isSearching = false;
      _safeNotifyListeners();
    }
  }

  /// Clears active search.
  void clearSearch() {
    _searchQuery = '';
    _searchResults = null;
    _isSearching = false;
    _searchPage = 1;
    _safeNotifyListeners();
  }

  /// Navigates to and highlights a specific category in tree view, auto-expanding all ancestors.
  void navigateToCategoryInTree(int categoryId) {
    // Build category map
    final categoryMap = {for (final c in _allCategories) c.id: c};
    final path = CategoryTreeHelper.buildPath(categoryMap, categoryId);

    // Expand all ancestors
    for (final ancestor in path) {
      _expandedNodeIds.add(ancestor.id);
    }

    _highlightedCategoryId = categoryId;
    clearSearch();
  }

  /// Clears highlighted category.
  void clearHighlight() {
    if (_highlightedCategoryId != null) {
      _highlightedCategoryId = null;
      _safeNotifyListeners();
    }
  }

  /// Clears active error message.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _safeNotifyListeners();
    }
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
