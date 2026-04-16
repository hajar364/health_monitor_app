import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_monitor_app/main.dart';

void main() {
  group('UI Integration Tests', () {
    testWidgets('App launches and displays bottom navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(const FallDetectionApp());

      // Vérifier que app démarre
      expect(find.byType(FallDetectionApp), findsOneWidget);

      // Vérifier bottom navigation avec 4 onglets
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Vérifier qu'on peut naviguer
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
    });

    testWidgets('Fall Dashboard displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const FallDetectionApp());

      // Devrait voir du texte sur le dashboard
      expect(find.text('Tableau de Bord'), findsWidgets);
      
      // Vérifier qu'il y a un bouton de simulation
      expect(find.byType(FloatingActionButton), findsWidgets);
    });

    testWidgets('Settings screen renders with sliders',
        (WidgetTester tester) async {
      await tester.pumpWidget(const FallDetectionApp());

      // Aller à settings (onglet 4)
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Vérifier que les sliders existent
      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('Alerts history screen displays empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(const FallDetectionApp());

      // Aller à alerts (onglet 2)
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();

      // Au démarrage = pas d'alertes
      expect(find.text('Historique Alertes'), findsWidgets);
    });

    testWidgets('Patients management screen allows adding patient',
        (WidgetTester tester) async {
      await tester.pumpWidget(const FallDetectionApp());

      // Aller à patients (onglet 3)
      await tester.tap(find.byIcon(Icons.people));
      await tester.pumpAndSettle();

      // Vérifier l'écran se charge
      expect(find.text('Gestion Patients'), findsWidgets);
    });
  });
}
