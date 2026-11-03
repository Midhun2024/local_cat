class DatabaseConstants {
  const DatabaseConstants._();

  static const String databaseName = 'local_cat.db';
  static const int databaseVersion = 1;

  static const String tableCategories = 'categories';

  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnParentId = 'parent_id';
  static const String columnCreatedAt = 'created_at';
}
