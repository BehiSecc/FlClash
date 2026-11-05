import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/usage_recorder.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/connection/statistics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

const _longName =
    'An application with a name so long that it cannot possibly fit on one '
    'line of a narrow window';

const _today = (
  apps: [
    (name: 'Chrome', upload: 1024, download: 3 * 1024 * 1024),
    (name: _longName, upload: 2048, download: 1024 * 1024),
    (name: '', upload: 0, download: 512),
  ],
  domains: [
    (name: 'googlevideo.com', upload: 100, download: 3 * 1024 * 1024),
    (name: 'example.com', upload: 3000, download: 1024 * 1024),
  ],
);

const _week = (
  apps: [(name: 'Slack', upload: 10, download: 20 * 1024 * 1024)],
  domains: [(name: 'slack.com', upload: 10, download: 20 * 1024 * 1024)],
);

const _empty = (apps: <UsageTotal>[], domains: <UsageTotal>[]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late int cleared;

  Future<void> pumpView(
    WidgetTester tester, {
    UsageOverview Function(UsageRange range) overview = _overviewOf,
    Size size = const Size(1000, 900),
  }) async {
    cleared = 0;
    container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(TestProfiles.new),
        usageOverviewProvider.overrideWith((ref, range) => overview(range)),
        usageBreakdownProvider.overrideWith(
          (ref, args) => [
            (name: 'breakdown of ${args.$3}', upload: 1, download: 2),
          ],
        ),
        usageRecorderProvider.overrideWithValue(
          UsageRecorder(
            write: (_) async {},
            prune: (_) async {},
            clear: () async => cleared++,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    container.read(viewSizeProvider.notifier).update((_) => size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: StatisticsView()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('shows the empty state when nothing was recorded', (
    tester,
  ) async {
    await pumpView(tester, overview: (_) => _empty);

    expect(find.text('No Statistics yet'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Apps'), findsOneWidget);
  });

  testWidgets('lists apps by total with their figures and a summary', (
    tester,
  ) async {
    await pumpView(tester);

    expect(find.text('Chrome'), findsOneWidget);
    expect(find.text('3MB'), findsWidgets);
    expect(find.text('3KB'), findsOneWidget);
    expect(find.text('Unknown'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('4MB'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Chrome')).dy,
      lessThan(tester.getTopLeft(find.text('Unknown')).dy),
    );
  });

  testWidgets('switches between apps and domains', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Domains'));
    await tester.pumpAndSettle();

    expect(find.text('googlevideo.com'), findsOneWidget);
    expect(find.text('Chrome'), findsNothing);

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();

    expect(find.text('Chrome'), findsOneWidget);
  });

  testWidgets('reads the range that was picked', (tester) async {
    await pumpView(
      tester,
      overview: (range) => range.days == 7 ? _week : _today,
    );

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();

    expect(find.text('Slack'), findsOneWidget);
    expect(find.text('Chrome'), findsNothing);
  });

  testWidgets('opens what an app spent its traffic on', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Chrome'));
    await tester.pumpAndSettle();

    expect(find.text('breakdown of Chrome'), findsOneWidget);
  });

  testWidgets('offers to turn on process lookup only on the apps tab', (
    tester,
  ) async {
    await pumpView(tester);
    container
        .read(patchClashConfigProvider.notifier)
        .update(
          (state) => state.copyWith(findProcessMode: FindProcessMode.off),
        );
    await tester.pump();

    expect(find.textContaining('Find process is off'), findsOneWidget);

    await tester.tap(find.text('Domains'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Find process is off'), findsNothing);

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();

    expect(
      container.read(patchClashConfigProvider).findProcessMode,
      FindProcessMode.always,
    );
    expect(find.textContaining('Find process is off'), findsNothing);
  });

  testWidgets('keeps very long names to one line on a narrow window', (
    tester,
  ) async {
    await pumpView(tester, size: const Size(320, 700));

    expect(tester.takeException(), isNull);
    final name = tester.widget<Text>(find.text(_longName));
    expect(name.overflow, TextOverflow.ellipsis);
    expect(name.maxLines, 1);
  });

  testWidgets('resets the statistics after a confirmation', (tester) async {
    await pumpView(tester);

    await tester.tap(find.byTooltip('Reset'));
    await tester.pumpAndSettle();
    expect(
      find.text('Clear all recorded usage? This cannot be undone.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(cleared, 0);

    await tester.tap(find.byTooltip('Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset').last);
    await tester.pumpAndSettle();

    expect(cleared, 1);
  });
}

UsageOverview _overviewOf(UsageRange range) => _today;
