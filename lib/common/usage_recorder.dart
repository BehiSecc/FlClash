import 'dart:async';

import 'package:fl_clash/common/print.dart';
import 'package:fl_clash/common/usage_accounting.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';

const usageFlushInterval = Duration(seconds: 5);

const usageRetention = Duration(days: 365);

/// Keeps what [UsageAccounting] collects and writes it out in batches, only
/// while something is pending.
class UsageRecorder {
  UsageRecorder({
    required this.write,
    required this.prune,
    required this.clear,
    this.onChanged,
    this.interval = usageFlushInterval,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _accounting = UsageAccounting(now: now);

  final Future<void> Function(Map<UsageKey, UsageDelta> deltas) write;
  final Future<void> Function(String beforeDay) prune;
  final Future<void> Function() clear;
  final void Function()? onChanged;
  final Duration interval;
  final DateTime Function() _now;
  final UsageAccounting _accounting;
  Timer? _timer;
  Future<void> _queue = Future.value();
  var _pruned = false;
  var _disposed = false;

  void onRequest(TrackerInfo info) {
    _accounting.onRequest(info);
    _schedule();
  }

  void onTraffic(Map<String, RequestTraffic> traffic) {
    _accounting.onTraffic(traffic);
    _schedule();
  }

  /// Never throws; deltas that could not be written wait for the next flush.
  Future<void> flush() => _enqueue(_flushOnce);

  Future<void> reset() => _enqueue(() async {
    _accounting.takePending();
    try {
      await clear();
    } catch (error) {
      commonPrint.log(
        'Usage reset failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
    }
    onChanged?.call();
  });

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _enqueue(Future<void> Function() task) {
    return _queue = _queue.then((_) => task());
  }

  void _schedule() {
    if (_timer != null || _disposed || !_accounting.hasPending) {
      return;
    }
    _timer = Timer(interval, () {
      _timer = null;
      unawaited(flush());
    });
  }

  Future<void> _flushOnce() async {
    if (!_accounting.hasPending) {
      return;
    }
    await _pruneOnce();
    final deltas = _accounting.takePending();
    try {
      await write(deltas);
      onChanged?.call();
    } catch (error) {
      _accounting.restore(deltas);
      commonPrint.log(
        'Usage flush failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
    }
    _schedule();
  }

  Future<void> _pruneOnce() async {
    if (_pruned) {
      return;
    }
    _pruned = true;
    try {
      await prune(usageDayOf(_now().subtract(usageRetention)));
    } catch (error) {
      commonPrint.log(
        'Usage prune failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
    }
  }
}
