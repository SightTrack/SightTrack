import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sighttrack/models/user.dart'; 
import 'package:sighttrack/screens/community/user_detail_screen.dart';
import 'package:sighttrack/util.dart'; 

// Mock User class
class MockUser extends User {
  final String mockId;
  final String mockDisplayUsername;
  final String? mockSchool;
  final String? mockProfilePicture;
  final String? mockEmail; // Added for completeness if User model has it

  MockUser({
    required this.mockId,
    required this.mockDisplayUsername,
    this.mockSchool,
    this.mockProfilePicture,
    this.mockEmail,
  }) : super(
          id: mockId,
          display_username: mockDisplayUsername,
          school: mockSchool,
          profilePicture: mockProfilePicture,
          email: mockEmail ?? '', // Assuming email is non-nullable in base User
          // Add any other required fields from the User model with default/mock values
        );

  // If User class has copyWith, it might be useful to override or mock it too
  // For simplicity, we are directly constructing it.

  // Need to ensure all fields required by the User constructor are provided.
  // If User is a generated Amplify model, it will have many more fields.
  // This mock might need to be more complex depending on the actual User model.
  // For now, this is a simplified version.
}

// Mock Util class for S3 fetching
class MockUtil {
  static Future<String?> fetchFromS3(String key) async {
    if (key == 'valid_s3_key.jpg') {
      return 'https://s3.example.com/valid_s3_key.jpg'; // Mocked S3 URL
    }
    return null; // Simulate S3 key not found or error
  }
}

// A custom NavigatorObserver to track pushed/popped routes
class MockNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? lastPopped;
  Route<dynamic>? lastPushed;
  Route<dynamic>? lastReplaced;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPopped = route;
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushed = route;
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    lastReplaced = newRoute;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void reset() {
    lastPopped = null;
    lastPushed = null;
    lastReplaced = null;
  }
}


void main() {
  // Store the original Util.fetchFromS3 and replace it with the mock
  final originalFetchFromS3 = Util.fetchFromS3;

  setUpAll(() {
    // Replace the static S3 fetch utility with our mock for all tests in this file
    Util.fetchFromS3 = MockUtil.fetchFromS3;
  });

  tearDownAll(() {
    // Restore the original utility
    Util.fetchFromS3 = originalFetchFromS3;
  });

  final mockUserWithSchool = MockUser(
    mockId: '1',
    mockDisplayUsername: 'Test User',
    mockSchool: 'Test School',
    mockProfilePicture: 'valid_s3_key.jpg',
  );

  final mockUserWithoutSchool = MockUser(
    mockId: '2',
    mockDisplayUsername: 'Another User',
    mockSchool: null,
    mockProfilePicture: 'invalid_key.jpg',
  );

  testWidgets('UserDetailScreen displays user data correctly and AppBar',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: UserDetailScreen(user: mockUserWithSchool),
    ));

    // Let FutureBuilder for S3 resolve
    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('User Details'), findsOneWidget);

    // Verify username
    expect(find.text('Test User'), findsOneWidget);

    // Verify school
    expect(find.text('Test School'), findsOneWidget);

    // Verify profile picture (CircleAvatar is present)
    expect(find.byType(CircleAvatar), findsOneWidget);
    // More specific check if needed, e.g., for NetworkImage after S3 fetch
    final avatarFinder = find.byType(CircleAvatar);
    final CircleAvatar avatarWidget = tester.widget(avatarFinder);
    expect(avatarWidget.backgroundImage, isA<NetworkImage>());


    // Test with user without school
    await tester.pumpWidget(MaterialApp(
      home: UserDetailScreen(user: mockUserWithoutSchool),
    ));

    // Let FutureBuilder for S3 resolve (mock will return null for invalid_key.jpg)
    await tester.pumpAndSettle();

    expect(find.text('Another User'), findsOneWidget);
    expect(find.text('No school information'), findsOneWidget);
    final avatarWidgetWithoutSchool = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatarWidgetWithoutSchool.backgroundImage, isNull); // No image for invalid key
    expect(find.byIcon(Icons.person), findsOneWidget); // Placeholder icon
  });

  testWidgets('UserDetailScreen back button navigates back',
      (WidgetTester tester) async {
    final mockObserver = MockNavigatorObserver();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailScreen(user: mockUserWithSchool))),
          child: const Text('Go to Details'),
        );
      })),
      navigatorObservers: [mockObserver],
    ));

    // Navigate to UserDetailScreen
    await tester.tap(find.text('Go to Details'));
    await tester.pumpAndSettle(); // Wait for navigation and S3 FutureBuilder

    expect(find.byType(UserDetailScreen), findsOneWidget);
    expect(mockObserver.lastPushed, isNotNull);
    mockObserver.reset(); // Reset before testing pop

    // Find the back button and tap it
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle(); // Wait for pop animation

    // Verify that UserDetailScreen is no longer in the widget tree
    expect(find.byType(UserDetailScreen), findsNothing);
    // Verify that Navigator.pop was called
    expect(mockObserver.lastPopped, isNotNull);
  });
}
