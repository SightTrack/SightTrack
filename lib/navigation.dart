import 'package:sighttrack/barrel.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class Navigation extends StatelessWidget {
  const Navigation({super.key});

  List<Widget> _buildScreens() {
    return [HomeScreen(), CaptureTypeScreen(), ProfileScreen()];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(CupertinoIcons.home),
        title: ('Home'),
        activeColorPrimary: CupertinoColors.activeGreen,
        inactiveColorPrimary: CupertinoColors.systemGrey,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: '/',
          routes: {
            '/allSightings': (final context) => const AllSightingsScreen(),
          },
        ),
      ),
      PersistentBottomNavBarItem(
        icon: Container(
          width: 76.0,
          height: 76.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.teal.shade500,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                spreadRadius: 2,
                blurRadius: 4,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.blur_on_sharp,
            color: Colors.white,
            size: 22.0,
          ),
        ),
        activeColorPrimary: Colors.teal.shade400,
        inactiveColorPrimary: Colors.teal.shade500,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: '/',
          routes: {
            '/info': (final context) => const CaptureTypeInfoScreen(),
            '/capture': (final context) => const CaptureScreen(),
            '/ac_setup': (final context) => const AreaCaptureSetup(),
            '/ac_home': (final context) => const AreaCaptureHome(),
          },
        ),
        activeColorSecondary: Colors.white,
        inactiveColorSecondary: Colors.white,
        contentPadding: 0,
        title: null,
        textStyle: TextStyle(fontSize: 0),
      ),
      PersistentBottomNavBarItem(
        icon: Icon(CupertinoIcons.profile_circled),
        title: ('Profile'),
        activeColorPrimary: CupertinoColors.activeGreen,
        inactiveColorPrimary: CupertinoColors.systemGrey,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: '/',
          routes: {'/settings': (final context) => const SettingsScreen()},
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    PersistentTabController controller = PersistentTabController(
      initialIndex: 0,
    );

    return PersistentTabView(
      context,
      controller: controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      hideNavigationBarWhenKeyboardAppears: true,
      padding: const EdgeInsets.only(top: 8),
      backgroundColor: Colors.white,
      isVisible: true,
      confineToSafeArea: true,
      navBarHeight: kBottomNavigationBarHeight,
      animationSettings: const NavBarAnimationSettings(
        navBarItemAnimation: ItemAnimationSettings(
          duration: Duration(milliseconds: 400),
          curve: Curves.ease,
        ),
        screenTransitionAnimation: ScreenTransitionAnimationSettings(
          animateTabTransition: true,
          duration: Duration(milliseconds: 200),
          screenTransitionAnimationType: ScreenTransitionAnimationType.fadeIn,
        ),
      ),
      navBarStyle: NavBarStyle.style15,
    );
  }
}
