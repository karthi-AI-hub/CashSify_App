import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../theme/app_theme.dart';
import 'package:cashsify_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:cashsify_app/features/ads/presentation/screens/watch_ads_screen.dart';
import 'package:cashsify_app/features/referrals/presentation/screens/referrals_screen.dart';
import 'package:cashsify_app/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:cashsify_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:cashsify_app/core/widgets/layout/exit_confirmation_wrapper.dart';

// Navigation state class
class NavigationState {
  final int currentIndex;
  final String title;
  final bool showNotifications;
  final bool showBonus;
  final List<Widget>? actions;

  const NavigationState({
    required this.currentIndex,
    required this.title,
    this.showNotifications = false,
    this.showBonus = false,
    this.actions,
  });

  NavigationState copyWith({
    int? currentIndex,
    String? title,
    bool? showNotifications,
    bool? showBonus,
    List<Widget>? actions,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      title: title ?? this.title,
      showNotifications: showNotifications ?? this.showNotifications,
      showBonus: showBonus ?? this.showBonus,
      actions: actions ?? this.actions,
    );
  }

  Widget getCurrentScreen() {
    switch (currentIndex) {
      case 0:
        return ExitConfirmationWrapper(
          screenIndex: 0,
          screenTitle: 'Refer & Earn',
          showNotifications: false,
          showBonus: false,
          child: const ReferralsScreen(),
        );
      case 1:
        return ExitConfirmationWrapper(
          screenIndex: 1,
          screenTitle: 'Watch Ads',
          showNotifications: false,
          showBonus: false,
          child: const WatchAdsScreen(),
        );
      case 2:
        return ExitConfirmationWrapper(
          screenIndex: 2,
          screenTitle: 'Home',
          showNotifications: true,
          showBonus: true,
          child: const DashboardScreen(),
        );
      case 3:
        return ExitConfirmationWrapper(
          screenIndex: 3,
          screenTitle: 'Wallet',
          showNotifications: false,
          showBonus: false,
          child: const WalletScreen(),
        );
      case 4:
        return ExitConfirmationWrapper(
          screenIndex: 4,
          screenTitle: 'Profile',
          showNotifications: false,
          showBonus: false,
          child: const ProfileScreen(),
        );
      default:
        return ExitConfirmationWrapper(
          screenIndex: 2,
          screenTitle: 'Home',
          showNotifications: true,
          showBonus: true,
          child: const DashboardScreen(),
        );
    }
  }
}

// Navigation notifier
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState(
    currentIndex: 2, // Default to Home
    title: 'Home',
    showNotifications: true,
    showBonus: true,
  ));

  void setIndex(int index) {
    switch (index) {
      case 0:
        state = state.copyWith(
          currentIndex: index,
          title: 'Refer & Earn',
          showNotifications: false,
          showBonus: false,
        );
        break;
      case 1:
        state = state.copyWith(
          currentIndex: index,
          title: 'Watch Ads',
          showNotifications: false,
          showBonus: false,
        );
        break;
      case 2:
        state = state.copyWith(
          currentIndex: index,
          title: 'Home',
          showNotifications: true,
          showBonus: true,
        );
        break;
      case 3:
        state = state.copyWith(
          currentIndex: index,
          title: 'Wallet',
          showNotifications: false,
          showBonus: false,
        );
        break;
      case 4:
        state = state.copyWith(
          currentIndex: index,
          title: 'Profile',
          showNotifications: false,
          showBonus: false,
        );
        break;
    }
  }

  void setReferralsScreen() {
    state = state.copyWith(
      title: 'Refer And Earn',
      showNotifications: false,
      showBonus: false,
    );
  }

  void setReferralHistoryScreen() {
    state = state.copyWith(
      title: 'Referral History',
      showNotifications: false,
      showBonus: false,
    );
  }
}

// Navigation provider
final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
}); 