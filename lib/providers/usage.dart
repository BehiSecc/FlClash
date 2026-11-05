import 'package:fl_clash/common/usage_accounting.dart';
import 'package:fl_clash/common/usage_recorder.dart';
import 'package:fl_clash/common/mixin.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/usage.g.dart';

@Riverpod(keepAlive: true)
class UsageRevision extends _$UsageRevision with AutoDisposeNotifierMixin {
  @override
  int build() => 0;
}

@Riverpod(keepAlive: true)
UsageRecorder usageRecorder(Ref ref) {
  final recorder = UsageRecorder(
    write: (deltas) => database.usageStatsDao.add(deltas),
    prune: (day) => database.usageStatsDao.pruneBefore(day),
    clear: () => database.usageStatsDao.clear(),
    onChanged: () {
      if (ref.mounted) {
        ref.read(usageRevisionProvider.notifier).update((value) => value + 1);
      }
    },
  );
  ref.onDispose(recorder.dispose);
  return recorder;
}

String? _sinceDayOf(UsageRange range) {
  final days = range.days;
  if (days == null) {
    return null;
  }
  final now = DateTime.now();
  return usageDayOf(DateTime(now.year, now.month, now.day - (days - 1)));
}

@riverpod
Future<UsageOverview> usageOverview(Ref ref, UsageRange range) async {
  ref.watch(usageRevisionProvider);
  final dao = database.usageStatsDao;
  final since = _sinceDayOf(range);
  final (apps, domains) = await (dao.byApp(since), dao.byDomain(since)).wait;
  return (apps: apps, domains: domains);
}

/// What [name], an app on the apps tab or a domain on the domains tab, spent
/// its traffic on.
@riverpod
Future<List<UsageTotal>> usageBreakdown(
  Ref ref,
  UsageRange range,
  UsageTab tab,
  String name,
) {
  ref.watch(usageRevisionProvider);
  final dao = database.usageStatsDao;
  final since = _sinceDayOf(range);
  return switch (tab) {
    UsageTab.apps => dao.domainsOfApp(name, since),
    UsageTab.domains => dao.appsOfDomain(name, since),
  };
}
