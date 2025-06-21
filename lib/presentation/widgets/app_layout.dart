import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/providers/navigation_provider.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_spacing.dart';

class AppLayout extends HookConsumerWidget {
  final Widget? child;

  const AppLayout({super.key, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(navigationProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget getCurrentScreen() {
      switch (state.currentIndex) {
        case 3:
          return const WalletScreen();
        default:
          return state.getCurrentScreen();
      }
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: AppBar(
            backgroundColor: colorScheme.primary,
            elevation: 0,
            title: Text(
              state.title,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            centerTitle: false,
            automaticallyImplyLeading: false,
            toolbarHeight: 68,
            titleSpacing: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: getCurrentScreen(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(isDark ? 0.10 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primaryContainer.withOpacity(isDark ? 0.22 : 0.7),
          selectedIndex: state.currentIndex,
          onDestinationSelected: (index) {
            ref.read(navigationProvider.notifier).setIndex(index);
          },
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Refer',
            ),
            NavigationDestination(
              icon: Icon(Icons.play_circle_outline),
              selectedIcon: Icon(Icons.play_circle),
              label: 'Watch',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
} 