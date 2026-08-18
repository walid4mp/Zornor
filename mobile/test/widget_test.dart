import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zynora_mobile/main.dart';

void main() {
  testWidgets('ZYNORA boots and shows splash', (tester) async {
    await tester.pumpWidget(const ZynoraRoot());
    expect(find.text('ZYNORA'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2300));
    expect(find.byType(Scaffold), findsWidgets);
  });
}
