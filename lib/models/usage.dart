typedef UsageTotal = ({String name, int upload, int download});

extension UsageTotalExt on UsageTotal {
  int get total => upload + download;
}

typedef UsageOverview = ({List<UsageTotal> apps, List<UsageTotal> domains});
