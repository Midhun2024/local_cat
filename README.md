# Category Manager — Flutter Machine Test Implementation

A production-quality Flutter application showcasing **MVC Architecture**, **SQLite** hierarchical category persistence with unlimited recursive nesting, **JSONPlaceholder REST API** integration with mock authentication, **GetIt** dependency injection, **Provider** state management, and **GoRouter** declarative navigation.

---

## 1. Project Purpose & Overview

The application satisfies the complete Flutter Machine Test requirements:
1. **Mock Authentication & Profile Flow**: Allows users to log in with mock IDs (1–10), fetches real user profiles from the JSONPlaceholder REST API (`/users`), displays user details safely, and allows logging out.
2. **Local SQLite Hierarchical Category System**: Implements unlimited depth category tree storage using `sqflite`. Supports adding root categories, adding subcategories under any node, case-insensitive whitespace-trimmed duplicate prevention under the same parent, transactions, and foreign key cascades.
3. **Recursive Search & Breadcrumb Paths**: Searches across the entire category hierarchy at all depths, displaying full ancestor paths (e.g., `Electronics → Mobile → Android → Samsung`), parent details, and direct children. Allows navigating directly from a search match to its position in the tree with auto-expanded ancestors.
4. **Limit & Pagination**: Provides typed paginated retrieval (`PaginatedResult<T>`) with page number, page size, total matching count, and previous/next page navigation.

---

## 2. Requirements & Versions

- **Flutter SDK**: 3.44.1 (channel stable)
- **Dart SDK**: 3.12.1 (sound null safety)
- **Platforms Supported**: Android, iOS, Windows desktop, macOS, Linux, Web.

---

## 3. Technology Stack & Package Choices

| Package | Version | Purpose & Rationale |
| :--- | :--- | :--- |
| `http` | `^1.6.0` | Standard, reliable HTTP client for REST API communication with JSONPlaceholder. |
| `sqflite` | `^2.4.5` | Centralized SQLite persistence for categories with foreign keys, indexes, and transactions. |
| `sqflite_common_ffi` | `^2.4.5` | Cross-platform SQLite FFI implementation enabling automated tests and Windows desktop support. |
| `path` | `^1.9.1` | Reliable path manipulation for database files across operating systems. |
| `get_it` | `^9.3.0` | Inversion of control and dependency injection, supporting constructor injection and decoupled testing. |
| `go_router` | `^18.1.2` | Declarative routing with route guards, redirect logic based on auth state, and deep link handling. |
| `provider` | `^6.1.5+1` | Reactive state management using `ChangeNotifier` controllers adhering to the MVC pattern. |
| `flutter_lints` | `^6.0.0` | Official static analysis lint rules ensuring high code quality and idiomatic Dart. |

---

## 4. Architecture: MVC (Model-View-Controller)

The codebase strictly adheres to the **Model-View-Controller** design pattern supported by a dedicated Service and Repository layer:

```
┌────────────────────────────────────────────────────────┐
│                        VIEW                            │
│  (Screens, Reusable Widgets, Forms, Dialogs, States)   │
└───────────────────────────▲────────────────────────────┘
                            │ listens via Provider
                            │ triggers user actions
┌───────────────────────────┴────────────────────────────┐
│                     CONTROLLER                         │
│  (ChangeNotifier, UI state, screen logic, no SQL/UI)   │
└───────────────────────────▲────────────────────────────┘
                            │ calls methods
┌───────────────────────────┴────────────────────────────┐
│                 REPOSITORIES & SERVICES                │
│  (AuthRepository, CategoryRepository, ApiService, DB)  │
└───────────────────────────▲────────────────────────────┘
                            │ fetches / persists
┌───────────────────────────┴────────────────────────────┐
│                        MODEL                           │
│  (UserModel, CategoryModel, CategoryTreeNode, Results) │
└────────────────────────────────────────────────────────┘
```

- **Model**: Immutable data structures, JSON serialization, SQLite mapping, and tree data entities (`UserModel`, `CategoryModel`, `CategoryTreeNode`, `CategorySearchItem`, `PaginatedResult`).
- **View**: Reactive UI screens (`LoginScreen`, `ProfileScreen`, `CategoryScreen`), recursive tree widgets (`CategoryTreeItem`), search cards (`CategorySearchResult`), and dialogs (`AddCategoryDialog`).
- **Controller**: State holders extending `ChangeNotifier` (`AuthController`, `CategoryController`) maintaining screen state, error messages, and tree expansion state without containing SQL or direct widget rendering.
- **Services & Repositories**: Data access layer executing network calls (`ApiService`) and database queries (`DatabaseService`), mapped cleanly through abstract repositories (`AuthRepository`, `CategoryRepository`).

---

## 5. Folder Structure

```
lib/
├── app/
│   ├── app.dart                   # Root application widget with MultiProvider & MaterialApp.router
│   ├── router/
│   │   └── app_router.dart        # GoRouter configuration & auth redirect guard
│   └── theme/
│       └── app_theme.dart         # Material 3 light theme definition
├── controllers/
│   ├── auth_controller.dart       # Auth state, login/logout, user session
│   └── category_controller.dart   # Categories, tree state, expansion, search, pagination
├── core/
│   ├── constants/
│   │   ├── api_constants.dart     # JSONPlaceholder endpoints & timeouts
│   │   ├── app_constants.dart     # Application-wide constants & defaults
│   │   └── database_constants.dart# Table and column schema constants
│   ├── errors/
│   │   └── app_exception.dart     # Custom exception hierarchy (Network, Server, Duplicate, etc.)
│   ├── utils/
│   │   ├── date_time_utils.dart   # ISO 8601 parsing and friendly formatting
│   │   └── validators.dart        # Input validators and name normalization
│   └── widgets/
│       ├── app_button.dart        # Reusable elevated/outlined button with loading spinner
│       ├── app_confirm_dialog.dart# Standardized confirmation dialog
│       ├── app_empty_view.dart    # Empty state placeholder with optional action
│       ├── app_error_view.dart    # Error state display with retry button
│       ├── app_loading_indicator.dart # Centered progress indicator with status message
│       ├── app_section_card.dart  # Material 3 card container with title & divider
│       └── app_text_field.dart    # Form input field with validation styling
├── data/
│   ├── models/
│   │   ├── category_model.dart    # Flat SQLite category entity
│   │   ├── category_search_item.dart # Rich search result item with path & relations
│   │   ├── category_tree_node.dart# Tree node entity, recursive builder, & path helper
│   │   ├── paginated_result.dart  # Generic pagination wrapper (page, totalCount, etc.)
│   │   └── user_model.dart        # Typed JSONPlaceholder user & company model
│   ├── repositories/
│   │   ├── auth_repository.dart   # Mock authentication logic via ApiService
│   │   └── category_repository.dart# Category CRUD, search, & pagination queries
│   └── services/
│       ├── api_service.dart       # HTTP client with timeouts, status codes, & error mapping
│       └── database_service.dart  # SQLite database instance, schema, foreign keys, & indexes
├── di/
│   └── service_locator.dart       # GetIt dependency injection registry
└── main.dart                      # App entry point (desktop FFI init, DI setup, runApp)

test/
├── controllers/
│   ├── auth_controller_test.dart
│   └── category_controller_test.dart
├── database/
│   └── database_service_test.dart
├── integration/
│   └── live_api_test.dart
├── unit/
│   ├── api_service_test.dart
│   ├── category_tree_test.dart
│   ├── paginated_result_test.dart
│   ├── user_model_test.dart
│   └── validators_test.dart
└── widgets/
    ├── add_category_dialog_test.dart
    ├── category_screen_test.dart
    ├── login_screen_test.dart
    └── profile_screen_test.dart
```

---

## 6. SQLite Schema & Uniqueness Policy

The SQLite database is versioned and configured with `PRAGMA foreign_keys = ON;`:

```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  parent_id INTEGER NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE CASCADE
);

CREATE INDEX idx_categories_parent_id
  ON categories (parent_id);

-- Enforces unique root category names (case-insensitive & trimmed)
CREATE UNIQUE INDEX idx_categories_root_unique
  ON categories (LOWER(TRIM(name)))
  WHERE parent_id IS NULL;

-- Enforces unique child category names under the SAME parent
CREATE UNIQUE INDEX idx_categories_child_unique
  ON categories (parent_id, LOWER(TRIM(name)))
  WHERE parent_id IS NOT NULL;
```

### Uniqueness Rules:
1. **Case-Insensitive & Trimmed**: `"Mobile"` and `" mobile "` are treated as duplicates.
2. **Scoped to Parent**: Duplicates are only rejected if they share the exact same `parent_id`.
3. **Cross-Parent Allowed**: `"Accessories"` can exist simultaneously under `"Electronics"` and `"Fashion"`.
4. **Root Protection**: Because SQLite treats `NULL != NULL` in standard UNIQUE constraints, a partial unique index (`WHERE parent_id IS NULL`) guarantees root category uniqueness.

---

## 7. REST API & Mock Login Behavior

- **API Endpoint**: `https://jsonplaceholder.typicode.com/users`
- **Mock Login Range**: User ID `1` through `10`.
- **Validation**: Any non-numeric string or number outside `1..10` displays a clear inline error.
- **Live User Retrieval**: The app fetches users from the live API, matches the record by ID, and populates the `UserModel` safely.
- **Disclaimer**: Clearly documents in the UI and documentation that JSONPlaceholder is a mock API for demonstration and evaluation, not production credential-based authentication.

---

## 8. Recursive Hierarchy & Search

- **Arbitrary Depth**: Category trees can be nested indefinitely (`Electronics → Mobile → Android → Samsung → Galaxy → ...`).
- **Cycle Prevention**: Ancestor check ensures an existing category cannot be placed under itself or any of its descendants.
- **Hierarchy Search**: Searches all categories across all nesting levels (not just visible/expanded rows) case-insensitively.
- **Rich Results**: Displays:
  - Exact category name.
  - Complete ancestor path (`Electronics → Mobile → Android → Samsung`).
  - Parent category chip.
  - Direct children count and preview.
  - **"View in Tree" Action**: Auto-expands all ancestor nodes, highlights the category, and navigates directly to it.

---

## 9. Dependency Injection (GetIt) & State Management (Provider)

- All services, repositories, and controllers are registered in `lib/di/service_locator.dart`.
- Dependencies are supplied via **constructor injection**, facilitating 100% isolated unit and widget testing with fakes.
- Root `MultiProvider` makes `AuthController` and `CategoryController` available throughout the widget tree.
- `GoRouter` uses `refreshListenable: authController` to immediately react to login and logout events.

---

## 10. Installation & Run Instructions

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Run the application
```bash
# Run on default connected device (e.g. Windows desktop, Chrome, or mobile emulator)
flutter run

# Specifically on Windows desktop:
flutter run -d windows

# Specifically in Chrome browser:
flutter run -d chrome
```

---

## 11. Automated Verification & Test Commands

### Format Code
```bash
dart format --output=none --set-exit-if-changed lib test
```

### Static Analysis
```bash
flutter analyze
```

### Run All Automated Tests
```bash
flutter test
```

### Test Suite Summary:
- **Total Tests**: 66 tests across 11 test suites.
- **Unit Tests**: User parsing, validators, tree construction, path building, cycle detection, pagination slicing, and API service error handling.
- **Database Tests**: In-memory SQLite schema creation, foreign key cascading, partial unique index enforcement, transactions, and close/reopen persistence.
- **Controller Tests**: State transitions, error handling, mock login, tree expansion, and search queries with fake repositories.
- **Widget Tests**: Login validation & error banners, Profile cards, Category tree expansion, Add dialog form, and Search breadcrumb rendering.
- **Live Integration Test**: Verifies live HTTP connectivity with JSONPlaceholder.

---

## 12. Known Limitations & Prerequisites

- **Authentication**: Uses JSONPlaceholder's public API with mock IDs 1–10. Production deployment would require a JWT/OAuth2 authentication backend.
- **Desktop SQLite**: SQLite on desktop platforms and during test execution relies on `sqflite_common_ffi`, which is pre-configured in `lib/main.dart` and the test suites.

---

## 13. Machine Test Deliverables & Technical Explanations

### 1. Project Architecture (MVC)
The application strictly implements the **Model-View-Controller (MVC)** architectural pattern supported by a dedicated Service/Repository layer:
- **Model** (`UserModel`, `CategoryModel`, `CategoryTreeNode`, `PaginatedResult`): Immutable data representations, JSON parsing, and tree traversal algorithms.
- **View** (`LoginScreen`, `ProfileScreen`, `CategoryScreen`, `CategoryTreeItem`, `CategorySearchResult`): Clean Material 3 UI widgets that observe state and emit user events.
- **Controller** (`AuthController`, `CategoryController`): State holders extending Provider's `ChangeNotifier` to coordinate business actions, maintain UI state, and notify views without containing raw SQL or widget rendering code.
- **Services & Repositories** (`ApiService`, `DatabaseService`, `AuthRepository`, `CategoryRepository`): Data access abstraction enabling constructor injection and 100% testable code.

### 2. State-Management Approach (Provider)
We selected **Provider** with `ChangeNotifier` because:
- **Natural MVC Fit**: Clearly separates presentation logic from UI widgets while avoiding unnecessary architectural boilerplate.
- **Performance & Granularity**: Efficient rebuilds using `context.watch`, `context.select`, and `context.read`.
- **Router Synchronization**: Integrates directly with `GoRouter.refreshListenable`, automatically redirecting users to `/profile` on login and `/login` on logout.

### 3. Local Database Selection (SQLite via `sqflite`)
We selected **SQLite (`sqflite` + `sqflite_common_ffi`)** over Hive, Isar, or Drift because:
- **Relational Integrity**: Hierarchical parent-child relationships naturally map to relational foreign keys (`FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE CASCADE`), guaranteeing clean cascading deletes and preventing orphaned nodes.
- **Partial Unique Indexes**: SQLite natively supports partial unique indexes (`CREATE UNIQUE INDEX ... WHERE parent_id IS NULL`), solving the SQL `NULL != NULL` limitation to enforce case-insensitive uniqueness at the database level for both root and child nodes.
- **ACID Transactions**: Atomic transactions (`db.transaction`) safeguard against corrupted tree state during multi-record batch operations.
- **Reliable Persistence**: Raw SQLite databases persist reliably across app restarts, closures, and crashes without binary schema corruption.

### 4. Category Hierarchy Implementation
- **Adjacency List Structure**: Each category stores its primary key `id` and nullable `parent_id`.
- **Dynamic Forest Construction**: `CategoryTreeHelper.buildTree()` converts flat database records into an in-memory recursive tree of `CategoryTreeNode`s in $O(N)$ time.
- **Unlimited Nesting Depth**: Supports arbitrary nesting depths ($A \to B \to C \to D \to E \to F \dots$) without any hardcoded level restrictions.
- **Cycle Prevention**: `CategoryTreeHelper.wouldCreateCycle()` performs ancestor traversal before any parent reassignment, preventing circular references.

### 5. Search and Pagination Approach
- **Deep Hierarchy Traversal**: Recursively searches the complete hierarchy across all levels (including collapsed and deeply nested nodes) using case-insensitive substring matching.
- **Rich Relationship Metadata**: Each search result displays:
  - The matched category name.
  - Its full root-to-leaf breadcrumb path (`Electronics → Mobile → Android → Samsung`).
  - Its parent category name.
  - Its direct subcategories preview.
- **View in Tree Navigation**: Tapping "View in Tree" on a search match auto-expands all ancestor nodes in the hierarchy and scrolls/highlights the target node.
- **Pagination Support**: Encapsulated in `PaginatedResult<T>` providing `page`, `page_size`, and `total_count` with bounds checking, previous/next page navigation, and SQLite `LIMIT`/`OFFSET` queries.

