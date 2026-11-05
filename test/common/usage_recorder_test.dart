import 'package:fl_clash/common/usage_accounting.dart';
import 'package:fl_clash/common/usage_recorder.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

TrackerInfo _request(String id) {
  return TrackerInfo(
    id: id,
    start: DateTime(2026),
    metadata: const Metadata(process: 'curl', host: 'www.example.com'),
    chains: const [],
    rule: '',
    rulePayload: '',
  );
}

void main() {
  late List<Map<UsageKey, UsageDelta>> writes;
  late List<String> prunes;
  late int clears;
  late int changes;
  late Exception? failure;
  late UsageRecorder recorder;

  UsageRecorder build({Duration interval = const Duration(hours: 1)}) {
    return UsageRecorder(
      interval: interval,
      now: () => DateTime(2026, 3, 9, 12),
      write: (deltas) async {
        if (failure != null) {
          throw failure!;
        }
        writes.add(deltas);
      },
      prune: (day) async => prunes.add(day),
      clear: () async => clears++,
      onChanged: () => changes++,
    );
  }

  setUp(() {
    writes = [];
    prunes = [];
    clears = 0;
    changes = 0;
    failure = null;
    recorder = build();
  });

  tearDown(() => recorder.dispose());

  const key = (day: '2026-03-09', app: 'curl', domain: 'example.com');

  test('flushes what is pending and then stays quiet', () async {
    recorder.onRequest(_request('a'));
    recorder.onTraffic({'a': (upload: 4, download: 9)});

    await recorder.flush();
    await recorder.flush();

    expect(writes, [
      {key: (upload: 4, download: 9)},
    ]);
    expect(changes, 1);
  });

  test('keeps the deltas of a failed flush for the next one', () async {
    recorder.onRequest(_request('a'));
    recorder.onTraffic({'a': (upload: 4, download: 9)});
    failure = Exception('disk full');

    await recorder.flush();

    expect(writes, isEmpty);
    expect(changes, 0);

    failure = null;
    recorder.onTraffic({'a': (upload: 5, download: 9)});
    await recorder.flush();

    expect(writes, [
      {key: (upload: 5, download: 9)},
    ]);
    expect(changes, 1);
  });

  test('prunes a year back once, before the first write', () async {
    recorder.onRequest(_request('a'));
    recorder.onTraffic({'a': (upload: 1, download: 0)});
    await recorder.flush();
    recorder.onTraffic({'a': (upload: 2, download: 0)});
    await recorder.flush();

    expect(prunes, ['2025-03-09']);
    expect(writes, hasLength(2));
  });

  test('does not prune when nothing was ever recorded', () async {
    await recorder.flush();

    expect(prunes, isEmpty);
  });

  test('writes on its own after the interval, only when pending', () async {
    recorder.dispose();
    recorder = build(interval: const Duration(milliseconds: 20));

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(writes, isEmpty);

    recorder.onRequest(_request('a'));
    recorder.onTraffic({'a': (upload: 4, download: 9)});
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(writes, hasLength(1));
  });

  test('reset drops pending deltas and clears the table', () async {
    recorder.onRequest(_request('a'));
    recorder.onTraffic({'a': (upload: 4, download: 9)});

    await recorder.reset();
    await recorder.flush();

    expect(clears, 1);
    expect(writes, isEmpty);
    expect(changes, 1);
  });
}
