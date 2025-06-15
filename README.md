# CashSify App

A Flutter application for managing earnings, referrals, and withdrawals with a clean, modern interface.

## Project Structure

```text
lib/
├── core/                      # Core functionality
│   ├── error/                # Error handling
│   ├── utils/                # Utilities
│   ├── widgets/              # Reusable widgets
│   ├── providers/            # State management
│   ├── services/             # Core services
│   ├── models/               # Core models
│   └── config/               # App configuration
├── app/                      # App-wide configuration
│   └── router/               # Routing configuration
├── theme/                    # Theme and styling
├── features/                 # Feature modules
│   ├── auth/                 # Authentication
│   ├── dashboard/            # Main dashboard
│   ├── profile/              # User profile management
│   ├── captcha/              # Captcha verification
│   ├── referrals/            # Referral system
│   ├── wallet/               # Wallet and withdrawals
│   └── ads/                  # Advertisement features
└── main.dart                 # Application entry point
```

## Feature Structure

Each feature follows Clean Architecture principles with this structure:

```text
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

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version)
- [Dart SDK](https://dart.dev/get-dart) (comes with Flutter)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd CashSify_App
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables:**
   - Create a `.env` file in the root directory
   - Add your Supabase configuration and other required environment variables

4. **Run the app:**
   ```bash
   flutter run
   ```

## Key Dependencies

- **[Flutter](https://flutter.dev/)** - UI framework
- **[Riverpod](https://riverpod.dev/)** - State management
- **[GoRouter](https://pub.dev/packages/go_router)** - Navigation and routing
- **[Supabase](https://supabase.com/)** - Backend services
- **[Google Fonts](https://pub.dev/packages/google_fonts)** - Typography

## Architecture

The app follows **Clean Architecture** principles with these key concepts:

- **Separation of concerns** - Each layer has a specific responsibility
- **Dependency injection** - Loose coupling between components
- **Repository pattern** - Abstraction of data sources
- **Feature-first organization** - Code organized by business features

### Core Components

- **[Error Handling](lib/core/error/)** - Centralized error management
- **[State Management](lib/core/providers/)** - Riverpod providers
- **[Navigation](lib/app/router/)** - GoRouter configuration
- **[Theme](lib/theme/)** - Material 3 design system

## Features

### 🔐 Authentication
Secure user authentication and authorization with Supabase.

### 📊 Dashboard
Main interface showing user statistics and quick actions.

### 👤 Profile Management
User profile settings and account management.

### 💰 Wallet & Withdrawals
Earnings tracking and withdrawal management.

### 🎯 Referral System
User referral program with tracking and rewards.

### 📱 Advertisement Integration
Watch ads to earn rewards functionality.

### 🔒 Captcha Verification
Security verification for sensitive operations.

## Error Handling

The app implements comprehensive error handling:

- **Centralized error management** in [`core/error`](lib/core/error/)
- **Custom error types** for different scenarios
- **Error boundary widgets** to catch and display errors gracefully
- **User-friendly error screens** with actionable feedback

## State Management

Built with **Riverpod** for predictable state management:

- **Global providers** in [`core/providers`](lib/core/providers/)
- **Feature-specific controllers** for local state
- **Reactive UI updates** based on state changes

## Navigation

Powered by **GoRouter** for modern navigation:

- **Declarative routing** configuration
- **Route guards** for authentication
- **Deep linking** support
- **Type-safe navigation**

## Theming

Modern **Material 3** design system:

- **Light and dark theme** support
- **Custom color schemes** and typography
- **Responsive design** for different screen sizes
- **Consistent visual language** across the app

## Development

### Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex business logic
- Keep functions small and focused

### Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Building

```bash
# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Build for web
flutter build web
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please:

1. Check the [existing issues](../../issues)
2. Create a new issue with detailed information
3. Contact the development team

---

**Happy coding! 🚀**