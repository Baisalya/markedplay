import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:markedplay/core/app_settings_provider.dart';
import 'package:markedplay/widgets/modern_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('error state remains usable on a compact screen', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettingsProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              title: 'Video unavailable',
              message: 'The file may have moved.',
              actionLabel: 'Try again',
              onAction: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Video unavailable'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
