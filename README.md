# Cashsify App

A Flutter application for managing earnings, referrals, and withdrawals.

## Project Structure

```
lib/
├── core/                      # Core functionality
│   ├── error/                # Error handling
│   │   └── app_error.dart    # Error type definitions
│   ├── utils/                # Utilities
│   │   ├── error_handler.dart
│   │   ├── app_utils.dart
│   │   └── logger.dart
│   ├── widgets/              # Reusable widgets
│   │   ├── error_screen.dart
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── loading_overlay.dart
│   │   └── theme_toggle.dart
│   ├── providers/            # State management
│   │   ├── auth_provider.dart
│   │   ├── error_provider.dart
│   │   └── theme_provider.dart
│   ├── services/             # Core services
│   │   └── supabase_service.dart
│   ├── models/               # Core models
│   └── config/               # App configuration
│       └── app_config.dart
├── app/                      # App-wide configuration
│   ├── theme/                # Theme configuration
│   │   └── app_theme.dart
│   ├── router/               # Routing
│   │   └── router.dart
│   └── constants/            # App constants
│       └── app_constants.dart
└── features/                 # Feature modules
    ├── auth/                 # Authentication
    ├── dashboard/            # Dashboard
    ├── profile/             # User profile
    ├── withdrawals/         # Withdrawals
    ├── captcha/            # Captcha
    ├── earnings/           # Earnings
    ├── referrals/          # Referrals
    └── watch_ads/          # Watch ads
```

## Feature Structure

Each feature follows this structure:
```
feature/
├── data/                    # Data layer
│   ├── repositories/        # Repository implementations
│   └── datasources/        # Data sources
│       ├── local/          # Local data sources
│       └── remote/         # Remote data sources
├── domain/                  # Domain layer
│   ├── entities/           # Business objects
│   └── repositories/       # Repository interfaces
└── presentation/           # Presentation layer
    ├── screens/           # UI screens
    ├── widgets/           # Feature-specific widgets
    └── controllers/       # State management
```

## Getting Started

1. Install dependencies:
```bash
flutter pub get
```

2. Set up environment variables:
- Copy `.env.example` to `.env`
- Fill in the required values

3. Run the app:
```bash
flutter run
```

## Dependencies

- Flutter
- Riverpod for state management
- GoRouter for navigation
- Supabase for backend
- Google Fonts for typography

## Architecture

The app follows Clean Architecture principles:
- Separation of concerns
- Dependency injection
- Repository pattern
- Feature-first organization

## Error Handling

- Centralized error handling in `core/error`
- Custom error types
- Error boundary widget
- Error screen for user feedback

## State Management

- Riverpod for state management
- Providers in `core/providers`
- Feature-specific controllers

## Navigation

- GoRouter for navigation
- Route guards for authentication
- Deep linking support

## Theme

- Material 3 design
- Light/dark theme support
- Custom theme configuration
