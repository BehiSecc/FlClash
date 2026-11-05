import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/features.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _sideBySideWidth = 640.0;

class StatisticsView extends ConsumerStatefulWidget {
  const StatisticsView({super.key});

  @override
  ConsumerState<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends ConsumerState<StatisticsView> {
  var _range = UsageRange.today;
  var _tab = UsageTab.apps;
  var _query = SearchQuery('');
  UsageOverview? _shown;

  Future<void> _reset() async {
    final appLocalizations = context.appLocalizations;
    final confirmed = await dialogs.showMessage(
      message: TextSpan(text: appLocalizations.usageResetTip),
      confirmText: appLocalizations.reset,
      destructive: true,
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await ref.read(usageRecorderProvider).reset();
  }

  List<UsageTotal> _visible(BuildContext context, UsageOverview overview) {
    final items = _tab == UsageTab.apps ? overview.apps : overview.domains;
    return items
        .where((item) => usageMatches(context, item, _query))
        .toList(growable: false);
  }

  Widget _buildControls() {
    final range = SegmentedControl<UsageRange>(
      segments: [for (final value in UsageRange.values) (value, value.label)],
      value: _range,
      onChanged: (value) => setState(() => _range = value),
    );
    final tab = SegmentedControl<UsageTab>(
      segments: [for (final value in UsageTab.values) (value, value.label)],
      value: _tab,
      onChanged: (value) => setState(() => _tab = value),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (_, constraints) => constraints.maxWidth >= _sideBySideWidth
            ? Row(
                spacing: 12,
                children: [
                  Expanded(child: range),
                  Expanded(child: tab),
                ],
              )
            : Column(spacing: 8, children: [range, tab]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UsageOverview? overview) {
    return Padding(
      padding: EdgeInsets.only(top: context.contentTopPadding, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _buildControls(),
          if (overview != null)
            UsageSummary(
              download: overview.apps.fold(0, (sum, e) => sum + e.download),
              upload: overview.apps.fold(0, (sum, e) => sum + e.upload),
            ),
          if (_tab == UsageTab.apps) const UsageFindProcessNotice(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final async = ref.watch(usageOverviewProvider(_range));
    final overview = async.value ?? _shown;
    _shown = overview;
    return Scaffold(
      title: PageLabel.statistics.label,
      searchState: AppBarSearchState(
        onSearch: (query) => setState(() => _query = SearchQuery(query)),
      ),
      iconActions: [
        IconButtonData(
          glyph: AppGlyphs.reset,
          tooltip: appLocalizations.reset,
          onPressed: _reset,
        ),
      ],
      body: Builder(
        builder: (context) {
          final items = overview == null
              ? const <UsageTotal>[]
              : _visible(context, overview);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, overview),
              Expanded(
                child: NullStatusSwitcher(
                  isLoading: overview == null && !async.hasError,
                  loadingStatus: const Center(child: ActivityIndicator.page()),
                  isEmpty: items.isEmpty,
                  isSearching: _query.isNotEmpty,
                  nullStatus: NullStatus(
                    label: appLocalizations.nullTip(
                      appLocalizations.statistics,
                    ),
                    illustration: NullStatusIllustration.data,
                  ),
                  child: UsageList(
                    items: items,
                    scope: (_range, _tab),
                    onSelected: (item) => showUsageBreakdown(
                      context,
                      range: _range,
                      tab: _tab,
                      name: item.name,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
