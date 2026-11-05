import 'dart:collection';

import 'package:fl_clash/common/usage_attribution.dart';
import 'package:fl_clash/models/models.dart';

typedef UsageKey = ({String day, String app, String domain});

typedef UsageDelta = ({int upload, int download});

const maxTrackedConnections = 20000;

/// The local calendar day as `yyyy-MM-dd`, which sorts as dates do.
String usageDayOf(DateTime time) {
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '${time.year.toString().padLeft(4, '0')}-$month-$day';
}

class _Connection {
  _Connection(this.app, this.domain, this.upload, this.download);

  final String app;
  final String domain;
  int upload;
  int download;
}

/// Turns the Core's announcements and cumulative reports into per-day,
/// per-app, per-domain deltas. The Core never says when a connection closes,
/// so the oldest are forgotten once [capacity] is passed.
class UsageAccounting {
  UsageAccounting({
    DateTime Function()? now,
    this.capacity = maxTrackedConnections,
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final int capacity;
  final _connections = LinkedHashMap<String, _Connection>();
  final _pending = <UsageKey, UsageDelta>{};

  bool get hasPending => _pending.isNotEmpty;

  int get trackedConnections => _connections.length;

  void onRequest(TrackerInfo info) {
    final metadata = info.metadata;
    if (isInnerConnection(metadata) || _connections.containsKey(info.id)) {
      return;
    }
    final connection = _Connection(
      usageAppOf(metadata),
      usageDomainOf(metadata),
      info.upload,
      info.download,
    );
    _connections[info.id] = connection;
    if (_connections.length > capacity) {
      _connections.remove(_connections.keys.first);
    }
    _add(connection, info.upload, info.download);
  }

  void onTraffic(Map<String, RequestTraffic> traffic) {
    for (final MapEntry(key: id, value: report) in traffic.entries) {
      final connection = _connections.remove(id);
      if (connection == null) {
        continue;
      }
      _connections[id] = connection;
      final upload = report.upload - connection.upload;
      final download = report.download - connection.download;
      if (upload > 0) {
        connection.upload = report.upload;
      }
      if (download > 0) {
        connection.download = report.download;
      }
      _add(connection, upload, download);
    }
  }

  Map<UsageKey, UsageDelta> takePending() {
    final taken = Map.of(_pending);
    _pending.clear();
    return taken;
  }

  void restore(Map<UsageKey, UsageDelta> deltas) {
    for (final MapEntry(:key, :value) in deltas.entries) {
      _merge(key, value.upload, value.download);
    }
  }

  void _add(_Connection connection, int upload, int download) {
    if (upload <= 0 && download <= 0) {
      return;
    }
    _merge(
      (day: usageDayOf(_now()), app: connection.app, domain: connection.domain),
      upload > 0 ? upload : 0,
      download > 0 ? download : 0,
    );
  }

  void _merge(UsageKey key, int upload, int download) {
    final current = _pending[key];
    _pending[key] = (
      upload: (current?.upload ?? 0) + upload,
      download: (current?.download ?? 0) + download,
    );
  }
}
