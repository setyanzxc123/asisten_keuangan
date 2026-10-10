import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/services/network_connectivity_service.dart';
import 'package:asisten_keuangan/core/services/financial_functions_service.dart';
import 'package:asisten_keuangan/features/assistant/data/assistant_provider.dart';
import 'package:asisten_keuangan/features/assistant/domain/chat_message.dart';
import 'package:asisten_keuangan/features/dashboard/presentation/dashboard_screen.dart';

class FailingFunctionsService extends FinancialFunctionsService {
  int callCount = 0;

  @override
  Future<FinancialIntentResult?> processFinancialIntent({
    String? text,
    String? storagePath,
    String? mediaBase64,
    String? mimeType,
  }) async {
    callCount++;
    throw Exception('Simulated Network Outage');
  }
}

void main() {
  group('NetworkConnectivityService Unit Tests', () {
    test('tracks and streams online and offline state transitions', () async {
      final service = NetworkConnectivityService();
      expect(service.status, equals(NetworkStatus.online));

      final states = <NetworkStatus>[];
      final sub = service.onStatusChanged.listen(states.add);

      service.updateStatus(NetworkStatus.offline);
      expect(service.status, equals(NetworkStatus.offline));

      service.updateStatus(NetworkStatus.online);
      expect(service.status, equals(NetworkStatus.online));

      await Future.delayed(const Duration(milliseconds: 10));
      expect(states, equals([NetworkStatus.offline, NetworkStatus.online]));

      await sub.cancel();
      service.dispose();
    });
  });

  group('Offline Assistant Interaction Tests', () {
    test('bypasses cloud function and commits locally when offline', () async {
      final failingFunctions = FailingFunctionsService();

      final container = ProviderContainer(
        overrides: [
            isOnlineProvider.overrideWithValue(false),
          financialFunctionsServiceProvider.overrideWithValue(failingFunctions),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(assistantProvider.notifier);
      await notifier.sendUserMessage(text: 'Beli bensin 50rb tunai');

      expect(failingFunctions.callCount, equals(0));

      final state = container.read(assistantProvider);
      expect(state.isThinking, isFalse);
      expect(state.messages.last.status, equals(MessageStatus.committed));
      expect(state.messages.last.sender, equals(MessageSender.banker));
      expect(state.messages.last.extractedTransaction?.amount, equals(50000));
    });
  });

  group('Dashboard Offline Banner Widget Tests', () {
    testWidgets('displays offline banner when network is offline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
              isOnlineProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(
        find.text('Mode Offline Aktif - Transaksi disimpan aman di penyimpanan lokal.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('hides offline banner when network is online', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWithValue(true),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(
        find.text('Mode Offline Aktif - Transaksi disimpan aman di penyimpanan lokal.'),
        findsNothing,
      );
    });
  });
}
