import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  List<PersistentBottomNavBarItem> _navBarsItems(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    final activeColor = isDarkMode ? Colors.white : Colors.grey[900];
    final inactiveColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_outlined),
        title: 'Home',
        activeColorPrimary: activeColor!,
        inactiveColorPrimary: inactiveColor!,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: '/',
          routes: {'/all_sightings': (context) => AllSightingsScreen()},
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.bar_chart_outlined),
        title: 'Data',
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: '/',
          routes: {},
        ),
      ),
      PersistentBottomNavBarItem(
        icon: CircleAvatar(
          radius: 54.0,
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          child: Icon(
            Icons.camera_alt_outlined,
            color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
            size: 42.0, // Increased from 28.0 to maintain proportion
          ),
        ),
        activeColorPrimary: Colors.transparent,
        inactiveColorPrimary: Colors.transparent,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: '/',
          routes: {
            '/info': (context) => CaptureTypeInfoScreen(),
            '/capture': (context) => const CaptureScreen(),
            '/ac_setup': (context) => const AreaCaptureSetup(),
            '/ac_home': (context) => const AreaCaptureHome(),
          },
        ),
        activeColorSecondary: Colors.transparent,
        inactiveColorSecondary: Colors.transparent,
        contentPadding: 0,
        title: null,
        textStyle: const TextStyle(fontSize: 0),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.people_outline),
        title: 'Community',
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_outline),
        title: 'Profile',
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    PersistentTabController controller = PersistentTabController(
      initialIndex: 0,
    );
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return PersistentTabView(
      context,
      controller: controller,
      screens: _buildScreens(),
      items: _navBarsItems(context),
      hideNavigationBarWhenKeyboardAppears: true,
      padding: const EdgeInsets.only(top: 8),
      backgroundColor: isDarkMode ? Colors.grey[850]! : Colors.white,
      isVisible: true,
      confineToSafeArea: true,
      navBarHeight: kBottomNavigationBarHeight,
      animationSettings: const NavBarAnimationSettings(
        navBarItemAnimation: ItemAnimationSettings(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
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
