# Auth Feature

This feature handles user authentication and authorization.

## Directory Structure

```
auth/
├── data/                      # Data layer
│   ├── repositories/          # Repository implementations
│   │   └── auth_repository_impl.dart
│   └── datasources/          # Data sources
│       ├── local/
│       │   └── auth_local_datasource.dart
│       └── remote/
│           └── auth_remote_datasource.dart
├── domain/                    # Domain layer
│   ├── entities/             # Business objects
│   │   └── user.dart
│   └── repositories/         # Repository interfaces
│       └── auth_repository.dart
└── presentation/             # Presentation layer
    ├── screens/             # UI screens
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   └── forgot_password_screen.dart
    ├── widgets/             # Feature-specific widgets
    │   └── auth_form.dart
    └── controllers/         # State management
        └── auth_controller.dart
```

## Usage

1. Import the feature:
```dart
import 'package:cashsify_app/features/auth/presentation/screens/login_screen.dart';
```

2. Use the screens:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const LoginScreen()),
);
```

3. Use the controllers:
```dart
final authController = ref.watch(authControllerProvider);
```

## Dependencies

- core/services/supabase_service.dart
- core/providers/auth_provider.dart
- core/widgets/error_screen.dart 