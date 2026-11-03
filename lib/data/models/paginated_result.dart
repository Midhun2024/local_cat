import '../../core/errors/app_exception.dart';

/// Generic container for paginated query results with pagination metadata.
class PaginatedResult<T> {
  PaginatedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  }) {
    if (page < 1) {
      throw const ValidationException('Page number must be 1 or greater.');
    }
    if (pageSize < 1) {
      throw const ValidationException('Page size must be 1 or greater.');
    }
    if (totalCount < 0) {
      throw const ValidationException('Total count cannot be negative.');
    }
  }

  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;

  int get totalPages {
    if (totalCount == 0) return 1;
    return (totalCount + pageSize - 1) ~/ pageSize;
  }

  bool get hasPreviousPage => page > 1;
  bool get hasNextPage => page < totalPages;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Helper factory to paginate a pre-filtered list (e.g., search results).
  factory PaginatedResult.fromAll({
    required List<T> allItems,
    required int page,
    required int pageSize,
  }) {
    if (page < 1) {
      throw const ValidationException('Page number must be 1 or greater.');
    }
    if (pageSize < 1) {
      throw const ValidationException('Page size must be 1 or greater.');
    }

    final totalCount = allItems.length;
    final startIndex = (page - 1) * pageSize;

    if (startIndex >= totalCount) {
      return PaginatedResult(
        items: const [],
        page: page,
        pageSize: pageSize,
        totalCount: totalCount,
      );
    }

    final endIndex = (startIndex + pageSize) > totalCount
        ? totalCount
        : (startIndex + pageSize);

    final pagedItems = allItems.sublist(startIndex, endIndex);

    return PaginatedResult(
      items: pagedItems,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }

  factory PaginatedResult.empty({int page = 1, int pageSize = 10}) {
    return PaginatedResult(
      items: const [],
      page: page,
      pageSize: pageSize,
      totalCount: 0,
    );
  }

  @override
  String toString() =>
      'PaginatedResult(page: $page/$totalPages, pageSize: $pageSize, totalCount: $totalCount, items: ${items.length})';
}
