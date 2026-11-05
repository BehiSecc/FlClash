import 'package:fl_clash/common/usage_accounting.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

TrackerInfo _request(
  String id, {
  int upload = 0,
  int download = 0,
  String process = 'curl',
  String host = 'www.example.com',
  String type = 'HTTPS',
}) {
  return TrackerInfo(
    id: id,
    upload: upload,
    download: download,
    start: DateTime(2026, 1, 1),
    metadata: Metadata(type: type, process: process, host: host),
    chains: const [],
    rule: '',
    rulePayload: '',
  );
}

UsageKey _key(String day, {String app = 'curl', String? domain}) =>
    (day: day, app: app, domain: domain ?? 'example.com');

void main() {
  late DateTime now;
  late UsageAccounting accounting;

  setUp(() {
    now = DateTime(2026, 3, 9, 12);
    accounting = UsageAccounting(now: () => now);
  });

  test('turns cumulative reports into deltas', () {
    accounting.onRequest(_request('a'));
    accounting.onTraffic({'a': (upload: 10, download: 100)});
    accounting.onTraffic({'a': (upload: 15, download: 100)});
    accounting.onTraffic({'a': (upload: 15, download: 250)});

    expect(accounting.takePending(), {
      _key('2026-03-09'): (upload: 15, download: 250),
    });
    expect(accounting.hasPending, isFalse);
  });

  test('counts the totals an announcement already carries once', () {
    accounting.onRequest(_request('a', upload: 5, download: 40));
    accounting.onRequest(_request('a', upload: 5, download: 40));
    accounting.onTraffic({'a': (upload: 8, download: 40)});

    expect(accounting.takePending(), {
      _key('2026-03-09'): (upload: 8, download: 40),
    });
  });

  test('excludes inner connections', () {
    accounting.onRequest(_request('inner', download: 9, type: 'Inner'));
    accounting.onTraffic({'inner': (upload: 3, download: 90)});

    expect(accounting.hasPending, isFalse);
    expect(accounting.trackedConnections, 0);
  });

  test('ignores a report that goes backwards', () {
    accounting.onRequest(_request('a'));
    accounting.onTraffic({'a': (upload: 10, download: 100)});
    accounting.onTraffic({'a': (upload: 4, download: 60)});
    accounting.onTraffic({'a': (upload: 12, download: 130)});

    expect(accounting.takePending(), {
      _key('2026-03-09'): (upload: 12, download: 130),
    });
  });

  test('ignores a report for a connection it was never told about', () {
    accounting.onTraffic({'ghost': (upload: 10, download: 100)});

    expect(accounting.hasPending, isFalse);
  });

  test('keeps apps and domains apart', () {
    accounting.onRequest(_request('a', process: 'curl'));
    accounting.onRequest(_request('b', process: 'ssh', host: 'git.other.net'));
    accounting.onRequest(_request('c', process: '', host: 'cdn.example.com'));
    accounting.onTraffic({
      'a': (upload: 1, download: 2),
      'b': (upload: 3, download: 4),
      'c': (upload: 5, download: 6),
    });

    expect(accounting.takePending(), {
      _key('2026-03-09'): (upload: 1, download: 2),
      _key('2026-03-09', app: 'ssh', domain: 'other.net'): (
        upload: 3,
        download: 4,
      ),
      _key('2026-03-09', app: ''): (upload: 5, download: 6),
    });
  });

  test('forgets the least recently used connection past its capacity', () {
    accounting = UsageAccounting(now: () => now, capacity: 2);
    accounting.onRequest(_request('a'));
    accounting.onRequest(_request('b'));
    accounting.onTraffic({'a': (upload: 1, download: 0)});
    accounting.onRequest(_request('c'));
    accounting.takePending();

    accounting.onTraffic({
      'a': (upload: 2, download: 0),
      'b': (upload: 7, download: 0),
      'c': (upload: 4, download: 0),
    });

    expect(accounting.trackedConnections, 2);
    expect(accounting.takePending(), {
      _key('2026-03-09'): (upload: 1 + 4, download: 0),
    });
  });

  test('books each delta on the day it arrives', () {
    accounting.onRequest(_request('a'));
    accounting.onTraffic({'a': (upload: 10, download: 0)});
    now = DateTime(2026, 3, 10, 0, 0, 1);
    accounting.onTraffic({'a': (upload: 25, download: 0)});

    expect(accounting.takePending(), {
      _key('2026-03-09'): (upload: 10, download: 0),
      _key('2026-03-10'): (upload: 15, download: 0),
    });
  });

  test('restores deltas after a failed flush and merges newer ones', () {
    accounting.onRequest(_request('a'));
    accounting.onTraffic({'a': (upload: 10, download: 100)});
    final failed = accounting.takePending();
    accounting.onTraffic({'a': (upload: 12, download: 100)});

    accounting.restore(failed);

    expect(accounting.takePending(), {
      _key('2026-03-09'): (upload: 12, download: 100),
    });
  });

  test('formats the day with zero padding', () {
    expect(usageDayOf(DateTime(2026, 1, 5)), '2026-01-05');
    expect(usageDayOf(DateTime(2026, 12, 31, 23, 59)), '2026-12-31');
  });
}
