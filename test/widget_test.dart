import 'package:flutter_test/flutter_test.dart';
import 'package:folio/main.dart';
import 'package:folio/ui/widgets/folio_logo.dart';
import 'package:folio/ui/screens/splash_screen.dart';

void main() {
  testWidgets('FolioApp launches with SplashScreen and FolioLogo smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FolioApp());

    // Verify SplashScreen is rendered
    expect(find.byType(SplashScreen), findsOneWidget);

    // Verify FolioLogo is present
    expect(find.byType(FolioLogo), findsWidgets);

    // Verify Title text is present
    expect(find.text('FOLIO'), findsOneWidget);
    expect(find.text('The Offline Document Studio'), findsOneWidget);
  });
}
