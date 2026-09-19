import 'package:dance_trainer_client/dance_trainer_client.dart';
import 'package:dance_trainer_flutter/training/screens.dart';
import 'package:dance_trainer_flutter/training/repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'catalog identifies development content and opens the selected routine',
    (tester) async {
      final entry = TrainingCatalogEntry(
        routineId: 'routine',
        title: 'Bachata practice',
        durationMs: 171000,
        version: 'v1',
        bundleJson: '{}',
        mediaPath: '/video.mp4',
        mediaSha256: 'hash',
        rankedAvailable: false,
      );
      TrainingCatalogEntry? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CatalogList(
              entries: [entry],
              onChoose: (entry) => chosen = entry,
            ),
          ),
        ),
      );
      expect(find.text('Find your rhythm'), findsOneWidget);
      expect(
        find.textContaining('Development practice, unranked'),
        findsOneWidget,
      );
      await tester.tap(find.text('Bachata practice'));
      expect(chosen, entry);
    },
  );
  testWidgets('empty catalog does not manufacture a playable routine', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatalogList(entries: const [], onChoose: (_) {}),
        ),
      ),
    );
    expect(find.text('No routines have been published yet.'), findsOneWidget);
  });
  testWidgets('retry panel invokes the recovery action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RetryPanel(
            message: 'Backend unavailable',
            retry: () => retried = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });
  testWidgets('insufficient tracking hides total and section judgments', (
    tester,
  ) async {
    final api = Client('http://localhost:8080/');
    addTearDown(api.close);
    final now = DateTime.utc(2026);
    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(
          repository: TrainingRepository(api, 'http://localhost:8080/'),
          entry: TrainingCatalogEntry(
            routineId: 'routine',
            title: 'Practice',
            durationMs: 8000,
            version: 'v1',
            bundleJson: '{}',
            mediaPath: '/video.mp4',
            mediaSha256: 'hash',
            rankedAvailable: false,
          ),
          attempt: TrainingAttempt(
            id: 1,
            userId: 'test',
            clientUuid: 'test-attempt-0001',
            routineId: 'routine',
            contentVersion: 'v1',
            modelVersion: 'model',
            mode: 'routine',
            ticket: 'test-only',
            createdAt: now,
            expiresAt: now,
            status: 'complete',
            nextChunk: 1,
            payloadBytes: 1,
          ),
          pending: true,
          result: {
            'totalScore': 9000,
            'coverage': 0.1,
            'judgmentAvailable': false,
            'rankReason': 'Not enough tracking coverage',
            'feedback': 'Step back into view.',
            'sections': [
              {'id': 's', 'title': 'Section 1', 'score': 9800, 'coverage': 0.1},
            ],
          },
        ),
      ),
    );
    expect(find.text('9000 / 10000'), findsNothing);
    expect(find.text('9800'), findsNothing);
    expect(find.text('Not enough tracking'), findsNWidgets(2));
    expect(find.text('Tracking coverage 10%'), findsOneWidget);
    expect(find.text('Saved on this phone · pending sync'), findsOneWidget);
  });
}
