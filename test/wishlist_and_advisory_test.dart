import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/features/wishlist/domain/wishlist_model.dart';
import 'package:asisten_keuangan/features/wishlist/data/wishlist_provider.dart';
import 'package:asisten_keuangan/features/reports/domain/advisory_preference.dart';
import 'package:asisten_keuangan/features/reports/data/monthly_ai_analysis_provider.dart';
import 'package:asisten_keuangan/features/reports/presentation/widgets/advisory_chip_selector.dart';
import 'package:asisten_keuangan/features/reports/presentation/widgets/wishlist_section_widget.dart';

void main() {
  group('WishlistModel Domain Tests', () {
    test('calculates progress and remaining amount correctly', () {
      final now = DateTime.now();
      final item = WishlistModel(
        id: 'w-1',
        title: 'MacBook Pro',
        targetAmount: 20000000,
        savedAmount: 5000000,
        createdAt: now,
      );

      expect(item.progressRatio, equals(0.25));
      expect(item.progressPercentage, equals(25.0));
      expect(item.remainingAmount, equals(15000000));
      expect(item.isAchieved, isFalse);

      final completedItem = item.copyWith(savedAmount: 20000000, isAchieved: true);
      expect(completedItem.progressRatio, equals(1.0));
      expect(completedItem.remainingAmount, equals(0.0));
      expect(completedItem.isAchieved, isTrue);
    });

    test('serializes toMap and fromMap accurately', () {
      final now = DateTime.now();
      final item = WishlistModel(
        id: 'w-2',
        title: 'Kamera Mirrorless',
        targetAmount: 12000000,
        savedAmount: 4000000,
        targetDate: now.add(const Duration(days: 60)),
        createdAt: now,
      );

      final map = item.toMap();
      final restored = WishlistModel.fromMap(map, 'w-2');

      expect(restored.id, equals('w-2'));
      expect(restored.title, equals('Kamera Mirrorless'));
      expect(restored.targetAmount, equals(12000000));
      expect(restored.savedAmount, equals(4000000));
      expect(restored.targetDate, isNotNull);
    });
  });

  group('WishlistNotifier State Management Tests', () {
    test('adds, allocates savings, and toggles achievement', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(wishlistProvider.notifier);
      expect(container.read(wishlistProvider).items.isNotEmpty, isTrue);

      await notifier.addWishlistItem(
        title: 'Monitor 4K',
        targetAmount: 6000000,
        savedAmount: 1000000,
      );

      final state = container.read(wishlistProvider);
      final added = state.items.firstWhere((i) => i.title == 'Monitor 4K');
      expect(added.targetAmount, equals(6000000));
      expect(added.savedAmount, equals(1000000));

      await notifier.allocateSavings(
        itemId: added.id,
        additionalAmount: 5000000,
      );

      final allocatedState = container.read(wishlistProvider);
      final updated = allocatedState.items.firstWhere((i) => i.id == added.id);
      expect(updated.savedAmount, equals(6000000));
      expect(updated.isAchieved, isTrue);

      await notifier.deleteWishlistItem(added.id);
      final deletedState = container.read(wishlistProvider);
      expect(deletedState.items.any((i) => i.id == added.id), isFalse);
    });
  });

  group('Advisory Style & Monthly Analysis Tests', () {
    test('updates advisory style state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(advisoryStyleProvider), equals(AdvisoryStyle.balanced));

      container.read(advisoryStyleProvider.notifier).selectStyle(AdvisoryStyle.frugal);
      expect(container.read(advisoryStyleProvider), equals(AdvisoryStyle.frugal));

      container.read(advisoryStyleProvider.notifier).selectStyle(AdvisoryStyle.growth);
      expect(container.read(advisoryStyleProvider), equals(AdvisoryStyle.growth));
    });

    test('generates local fallback analysis when executed', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final analysisNotifier = container.read(monthlyAiAnalysisProvider.notifier);
      await analysisNotifier.generateAnalysis();

      final state = container.read(monthlyAiAnalysisProvider);
      expect(state.isLoading, isFalse);
      expect(state.result, isNotNull);
      expect(state.result!.headline.isNotEmpty, isTrue);
      expect(state.result!.narrative.isNotEmpty, isTrue);
    });
  });

  group('Presentation Widgets Tests', () {
    testWidgets('AdvisoryChipSelector renders chips and handles selection', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AdvisoryChipSelector(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('GAYA PENASIHAT BANKER'), findsOneWidget);
      expect(find.text('Seimbang'), findsOneWidget);
      expect(find.text('Ketat / Hemat'), findsOneWidget);
      expect(find.text('Pertumbuhan Investasi'), findsOneWidget);
      expect(find.text('Ringkas Eksekutif'), findsOneWidget);

      await tester.tap(find.text('Ketat / Hemat'));
      await tester.pump();
    });

    testWidgets('WishlistSectionWidget renders target items and action buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WishlistSectionWidget(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('TARGET IMPIAN & WISHLIST'), findsOneWidget);
      expect(find.text('Tambah'), findsOneWidget);
      expect(find.text('Dana Darurat 3 Bulan'), findsOneWidget);
      expect(find.text('Upgrade Laptop Kerja'), findsOneWidget);
    });
  });
}
