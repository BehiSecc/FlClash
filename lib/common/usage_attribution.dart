import 'dart:io';

import 'package:fl_clash/models/models.dart';

const _innerConnectionType = 'inner';

const _secondLevelLabels = {'com', 'co', 'net', 'org', 'ac', 'edu', 'gov'};

final _pathSeparator = RegExp(r'[\\/]');

final _addressBrackets = RegExp(r'^\[|\]$');

/// The Core opens inner connections for a dialer proxy or for its own DNS
/// lookups; the traffic they carry is already counted on the connection that
/// caused them.
bool isInnerConnection(Metadata metadata) {
  return metadata.type.toLowerCase() == _innerConnectionType;
}

/// The outermost `.app` bundle of the executable's path, otherwise the process
/// name without `.exe`; empty when neither is known.
String usageAppOf(Metadata metadata) {
  for (final segment in metadata.processPath.split(_pathSeparator)) {
    if (segment.length > 4 && segment.toLowerCase().endsWith('.app')) {
      return segment.substring(0, segment.length - 4);
    }
  }
  final process = metadata.process.trim();
  if (process.toLowerCase().endsWith('.exe')) {
    return process.substring(0, process.length - 4);
  }
  return process;
}

/// The registrable domain of the host, or the destination address when the
/// connection has no host. Addresses are never rolled up.
String usageDomainOf(Metadata metadata) {
  final host = _normalized(metadata.host);
  if (host.isEmpty) {
    return metadata.destinationIP;
  }
  if (InternetAddress.tryParse(host.replaceAll(_addressBrackets, '')) != null) {
    return host;
  }
  final labels = host.split('.');
  if (labels.length <= 2) {
    return host;
  }
  final keep =
      labels.last.length == 2 &&
          _secondLevelLabels.contains(labels[labels.length - 2])
      ? 3
      : 2;
  return labels.skip(labels.length - keep).join('.');
}

String _normalized(String host) {
  final lower = host.trim().toLowerCase();
  return lower.endsWith('.') ? lower.substring(0, lower.length - 1) : lower;
}
