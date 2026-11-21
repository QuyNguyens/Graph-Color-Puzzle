import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_coloring/app.dart';
import 'package:graph_coloring/features/campaign/presentation/screens/campaign_home_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GraphColoringApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CampaignHomeScreen), findsOneWidget);
  });
}
