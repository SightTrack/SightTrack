import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sighttrack/barrel.dart';

class Navigation extends StatelessWidget {
  const Navigation({super.key});

  List<Widget> _buildScreens() {
    return [
      HomeScreen(),
      DataScreen(),
      CaptureTypeScreen(),
      CommunityScreen(),
      ProfileScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.map),
        title: 'Home',
        activeColorPrimary: CupertinoColors.activeGreen,
        inactiveColorPrimary: CupertinoColors.systemGrey,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: '/',
          routes: {'/all_sightings': (context) => AllSightingsScreen()},
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.chart_bar),
        title: 'Data',
        activeColorPrimary: CupertinoColors.activeGreen,
        inactiveColorPrimary: CupertinoColors.systemGrey,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: '/',
          routes: {},
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
                offset: const Offset(0, 3),
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
            '/info': (context) => CaptureTypeInfoScreen(),
            '/capture': (context) => const CaptureScreen(),
            '/ac_setup': (context) => const AreaCaptureSetup(),
            '/ac_home': (context) => const AreaCaptureHome(),
          },
        ),
        activeColorSecondary: Colors.white,
        inactiveColorSecondary: Colors.white,
        contentPadding: 0,
        title: null,
        textStyle: const TextStyle(fontSize: 0),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.person_2),
        title: 'Community',
        activeColorPrimary: CupertinoColors.activeGreen,
        inactiveColorPrimary: CupertinoColors.systemGrey,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: '/',
          routes: {},
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.profile_circled),
        title: 'Profile',
        activeColorPrimary: CupertinoColors.activeGreen,
        inactiveColorPrimary: CupertinoColors.systemGrey,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: '/',
          routes: {'/settings': (context) => SettingsScreen()},
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
