part of 'database.dart';

@DataClassName('UsageStatRow')
class UsageStats extends Table {
  @override
  String get tableName => 'usage_stats';

  TextColumn get day => text()();

  TextColumn get app => text()();

  TextColumn get domain => text()();

  IntColumn get upload => integer()();

  IntColumn get download => integer()();

  @override
  Set<Column> get primaryKey => {day, app, domain};
}

@DriftAccessor(tables: [UsageStats])
class UsageStatsDao extends DatabaseAccessor<Database>
    with _$UsageStatsDaoMixin {
  UsageStatsDao(super.attachedDatabase);

  /// Adds to the stored figures; a key seen before keeps what it had.
  Future<void> add(Map<UsageKey, UsageDelta> deltas) {
    return batch((b) {
      for (final MapEntry(:key, :value) in deltas.entries) {
        b.insert(
          usageStats,
          UsageStatsCompanion.insert(
            day: key.day,
            app: key.app,
            domain: key.domain,
            upload: value.upload,
            download: value.download,
          ),
          onConflict: DoUpdate<$UsageStatsTable, UsageStatRow>.withExcluded(
            (old, excluded) => UsageStatsCompanion.custom(
              upload: old.upload + excluded.upload,
              download: old.download + excluded.download,
            ),
          ),
        );
      }
    });
  }

  Future<List<UsageTotal>> byApp(String? sinceDay) =>
      _totals(usageStats.app, sinceDay);

  Future<List<UsageTotal>> byDomain(String? sinceDay) =>
      _totals(usageStats.domain, sinceDay);

  Future<List<UsageTotal>> domainsOfApp(String app, String? sinceDay) {
    return _totals(
      usageStats.domain,
      sinceDay,
      where: usageStats.app.equals(app),
    );
  }

  Future<List<UsageTotal>> appsOfDomain(String domain, String? sinceDay) {
    return _totals(
      usageStats.app,
      sinceDay,
      where: usageStats.domain.equals(domain),
    );
  }

  Future<int> clear() => usageStats.remove((_) => const Constant(true));

  Future<int> pruneBefore(String day) =>
      usageStats.remove((t) => t.day.isSmallerThanValue(day));

  Future<List<UsageTotal>> _totals(
    GeneratedColumn<String> name,
    String? sinceDay, {
    Expression<bool>? where,
  }) async {
    final upload = usageStats.upload.sum();
    final download = usageStats.download.sum();
    final query = selectOnly(usageStats)
      ..addColumns([name, upload, download])
      ..groupBy([name]);
    final filters = [
      ?where,
      if (sinceDay != null) usageStats.day.isBiggerOrEqualValue(sinceDay),
    ];
    if (filters.isNotEmpty) {
      query.where(filters.reduce((a, b) => a & b));
    }
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          name: row.read(name)!,
          upload: row.read(upload) ?? 0,
          download: row.read(download) ?? 0,
        ),
    ]..sort(_byTotalThenName);
  }
}

int _byTotalThenName(UsageTotal a, UsageTotal b) {
  final byTotal = b.total.compareTo(a.total);
  return byTotal != 0 ? byTotal : a.name.compareTo(b.name);
}
