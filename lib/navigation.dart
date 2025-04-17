import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:sighttrack/screens/capture/area_capture.dart';
import 'package:sighttrack/screens/capture/area_capture_home.dart';
import 'package:sighttrack/screens/capture/capture.dart';
import 'package:sighttrack/screens/capture/capture_type.dart';
import 'package:sighttrack/screens/home/all_sightings.dart';
import 'package:sighttrack/screens/home/home.dart';
import 'package:sighttrack/screens/profile/profile.dart';
import 'package:sighttrack/screens/profile/settings.dart';

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
          initialRoute: '/home',
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
            Icons.camera_alt,
            color: Colors.white,
            size: 22.0, // Kept icon size at 32.0
          ),
        ),
        activeColorPrimary: Colors.teal.shade400,
        inactiveColorPrimary: Colors.teal.shade500,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: '/captureType',
          routes: {
            '/info': (final context) => const CaptureTypeInfoScreen(),
            '/capture': (final context) => const CaptureScreen(),
            '/area_capture': (final context) => const AreaCaptureScreen(),
            '/area_capture_home': (final context) => const AreaCaptureHome(),
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
          initialRoute: '/profile',
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
