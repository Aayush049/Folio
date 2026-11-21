import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/core/folio_breakpoints.dart';
import 'package:folio/core/folio_shortcuts.dart';

void main() {
  group('FolioBreakpoints & Responsive Extensions', () {
    testWidgets('identifies compact screen size under 600dp', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late FolioScreenSize size;
      late bool isCompact;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              size = context.screenSize;
              isCompact = context.isCompact;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(size, equals(FolioScreenSize.compact));
      expect(isCompact, isTrue);
    });

    testWidgets('identifies medium screen size between 600dp and 1024dp', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late FolioScreenSize size;
      late bool isMedium;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              size = context.screenSize;
              isMedium = context.isMedium;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(size, equals(FolioScreenSize.medium));
      expect(isMedium, isTrue);
    });

    testWidgets('identifies expanded screen size above 1024dp', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late FolioScreenSize size;
      late bool isExpanded;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              size = context.screenSize;
              isExpanded = context.isExpanded;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(size, equals(FolioScreenSize.expanded));
      expect(isExpanded, isTrue);
    });

    testWidgets('ResponsiveContainer respects maxWidth constraint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              maxWidth: 800,
              child: SizedBox(
                key: Key('content'),
                width: double.infinity,
                height: 100,
              ),
            ),
          ),
        ),
      );

      final renderBox = tester.renderObject<RenderBox>(
        find.byKey(const Key('content')),
      );
      expect(renderBox.size.width, equals(800));
    });
  });

  group('FolioShortcuts', () {
    testWidgets('triggers callback on shortcut intent', (tester) async {
      bool scanTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: FolioShortcuts(
            onNewScan: () => scanTriggered = true,
            child: const Scaffold(body: Text('Shortcut Test')),
          ),
        ),
      );

      // Invoke the NewScanIntent directly through Actions
      final context = tester.element(find.text('Shortcut Test'));
      Actions.invoke(context, const NewScanIntent());

      expect(scanTriggered, isTrue);
    });
  });
}
