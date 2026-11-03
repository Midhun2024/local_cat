import 'package:flutter_test/flutter_test.dart';
import 'package:local_cat/core/utils/validators.dart';

void main() {
  group('Validators.validateUserId', () {
    test('returns null for valid IDs 1 through 10', () {
      for (int i = 1; i <= 10; i++) {
        expect(Validators.validateUserId('$i'), isNull);
        expect(Validators.validateUserId('  $i  '), isNull); // with whitespace
      }
    });

    test('returns error for empty or whitespace-only input', () {
      expect(Validators.validateUserId(null), contains('enter a user ID'));
      expect(Validators.validateUserId(''), contains('enter a user ID'));
      expect(Validators.validateUserId('   '), contains('enter a user ID'));
    });

    test('returns error for non-integer input', () {
      expect(Validators.validateUserId('abc'), contains('valid integer'));
      expect(Validators.validateUserId('1.5'), contains('valid integer'));
    });

    test('returns error for out-of-range IDs', () {
      expect(Validators.validateUserId('0'), contains('between 1 and 10'));
      expect(Validators.validateUserId('-1'), contains('between 1 and 10'));
      expect(Validators.validateUserId('11'), contains('between 1 and 10'));
      expect(Validators.validateUserId('999'), contains('between 1 and 10'));
    });
  });

  group('Validators.validateCategoryName', () {
    test('returns null for valid category names', () {
      expect(Validators.validateCategoryName('Electronics'), isNull);
      expect(Validators.validateCategoryName('Mobile Phones'), isNull);
      expect(Validators.validateCategoryName('A'), isNull);
    });

    test('returns error for null, empty, or whitespace name', () {
      expect(
        Validators.validateCategoryName(null),
        contains('cannot be empty'),
      );
      expect(Validators.validateCategoryName(''), contains('cannot be empty'));
      expect(
        Validators.validateCategoryName('   '),
        contains('cannot be empty'),
      );
    });

    test('returns error for names exceeding 80 characters', () {
      final longName = 'A' * 81;
      expect(
        Validators.validateCategoryName(longName),
        contains('cannot exceed 80'),
      );
    });
  });

  group('Validators.normalizeCategoryName', () {
    test('trims surrounding whitespace and lowercases', () {
      expect(Validators.normalizeCategoryName('  Mobile  '), 'mobile');
      expect(Validators.normalizeCategoryName('ELECTRONICS'), 'electronics');
      expect(
        Validators.normalizeCategoryName('Gaming Laptops'),
        'gaming laptops',
      );
    });
  });
}
