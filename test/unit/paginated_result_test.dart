import 'package:flutter_test/flutter_test.dart';
import 'package:local_cat/core/errors/app_exception.dart';
import 'package:local_cat/data/models/paginated_result.dart';

void main() {
  group('PaginatedResult', () {
    test('calculates totalPages and navigation flags correctly', () {
      final res1 = PaginatedResult(
        items: [1, 2, 3],
        page: 1,
        pageSize: 3,
        totalCount: 10,
      );

      expect(res1.totalPages, 4); // ceil(10 / 3) = 4
      expect(res1.hasPreviousPage, isFalse);
      expect(res1.hasNextPage, isTrue);

      final res2 = PaginatedResult(
        items: [4, 5, 6],
        page: 2,
        pageSize: 3,
        totalCount: 10,
      );
      expect(res2.hasPreviousPage, isTrue);
      expect(res2.hasNextPage, isTrue);

      final resLast = PaginatedResult(
        items: [10],
        page: 4,
        pageSize: 3,
        totalCount: 10,
      );
      expect(resLast.hasPreviousPage, isTrue);
      expect(resLast.hasNextPage, isFalse);
    });

    test('validates page, pageSize, and totalCount bounds', () {
      expect(
        () => PaginatedResult(items: [], page: 0, pageSize: 10, totalCount: 0),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => PaginatedResult(items: [], page: 1, pageSize: 0, totalCount: 0),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => PaginatedResult(items: [], page: 1, pageSize: 10, totalCount: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('PaginatedResult.fromAll slices correctly', () {
      final items = List.generate(25, (i) => 'Item $i');

      final page1 = PaginatedResult.fromAll(
        allItems: items,
        page: 1,
        pageSize: 10,
      );
      expect(page1.items.length, 10);
      expect(page1.items.first, 'Item 0');
      expect(page1.items.last, 'Item 9');
      expect(page1.totalCount, 25);
      expect(page1.totalPages, 3);

      final page3 = PaginatedResult.fromAll(
        allItems: items,
        page: 3,
        pageSize: 10,
      );
      expect(page3.items.length, 5); // remaining 5
      expect(page3.items.first, 'Item 20');
      expect(page3.items.last, 'Item 24');

      final pageOutOfRange = PaginatedResult.fromAll(
        allItems: items,
        page: 5,
        pageSize: 10,
      );
      expect(pageOutOfRange.items, isEmpty);
      expect(pageOutOfRange.totalCount, 25);
    });

    test('PaginatedResult.empty creates valid empty instance', () {
      final empty = PaginatedResult.empty();
      expect(empty.items, isEmpty);
      expect(empty.totalCount, 0);
      expect(empty.page, 1);
      expect(empty.totalPages, 1);
      expect(empty.hasPreviousPage, isFalse);
      expect(empty.hasNextPage, isFalse);
    });
  });
}
