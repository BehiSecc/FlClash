import 'package:drift/native.dart';
import 'package:fl_clash/common/usage_accounting.dart';
import 'package:fl_clash/database/database.dart';
import 'package:flutter_test/flutter_test.dart';

UsageKey _key(String day, String app, String domain) =>
    (day: day, app: app, domain: domain);

void main() {
  late Database database;

  setUp(() {
    database = Database(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  Future<void> seed() => database.usageStatsDao.add({
    _key('2026-03-07', 'Chrome', 'example.com'): (upload: 1, download: 100),
    _key('2026-03-08', 'Chrome', 'example.com'): (upload: 2, download: 200),
    _key('2026-03-09', 'Chrome', 'cdn.net'): (upload: 3, download: 300),
    _key('2026-03-09', '', 'example.com'): (upload: 10, download: 10),
    _key('2026-03-09', 'curl', 'example.com'): (upload: 0, download: 5),
  });

  test('adds to a key it has seen instead of replacing it', () async {
    await seed();
    await database.usageStatsDao.add({
      _key('2026-03-09', 'curl', 'example.com'): (upload: 7, download: 5),
    });

    final apps = await database.usageStatsDao.byApp('2026-03-09');

    expect(apps.firstWhere((total) => total.name == 'curl'), (
      name: 'curl',
      upload: 7,
      download: 10,
    ));
    expect(await database.usageStats.count.getSingle(), 5);
  });

  test('totals per app, biggest first, over a range', () async {
    await seed();

    expect(await database.usageStatsDao.byApp(null), [
      (name: 'Chrome', upload: 6, download: 600),
      (name: '', upload: 10, download: 10),
      (name: 'curl', upload: 0, download: 5),
    ]);
    expect(await database.usageStatsDao.byApp('2026-03-08'), [
      (name: 'Chrome', upload: 5, download: 500),
      (name: '', upload: 10, download: 10),
      (name: 'curl', upload: 0, download: 5),
    ]);
    expect(await database.usageStatsDao.byApp('2026-03-10'), isEmpty);
  });

  test('totals per domain over a range', () async {
    await seed();

    expect(await database.usageStatsDao.byDomain('2026-03-09'), [
      (name: 'cdn.net', upload: 3, download: 300),
      (name: 'example.com', upload: 10, download: 15),
    ]);
  });

  test('breaks an app down by domain and a domain down by app', () async {
    await seed();

    expect(await database.usageStatsDao.domainsOfApp('Chrome', null), [
      (name: 'cdn.net', upload: 3, download: 300),
      (name: 'example.com', upload: 3, download: 300),
    ]);
    expect(
      await database.usageStatsDao.appsOfDomain('example.com', '2026-03-09'),
      [
        (name: '', upload: 10, download: 10),
        (name: 'curl', upload: 0, download: 5),
      ],
    );
  });

  test('prunes days before a cutoff and clears everything', () async {
    await seed();

    expect(await database.usageStatsDao.pruneBefore('2026-03-08'), 1);
    expect(await database.usageStats.count.getSingle(), 4);
    expect(await database.usageStatsDao.clear(), 4);
    expect(await database.usageStats.count.getSingle(), 0);
  });
}
