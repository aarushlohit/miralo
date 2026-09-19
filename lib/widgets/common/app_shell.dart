import 'package:flutter/material.dart';
import 'app_sidebar_drawer.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const AppShell({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktopOrTablet = MediaQuery.of(context).size.width >= 768;

    if (isDesktopOrTablet) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            const AppSidebarDrawer(isPersistent: true),
            Expanded(
              child: Scaffold(
                backgroundColor: backgroundColor,
                appBar: appBar,
                body: child,
                floatingActionButton: floatingActionButton,
                bottomNavigationBar: bottomNavigationBar,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: const AppSidebarDrawer(isPersistent: false),
      appBar: appBar,
      body: child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
