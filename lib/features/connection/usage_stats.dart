import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/usage.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const usageRowExtent = 76.0;

const _usageTotalWidth = 88.0;

String usageNameOf(BuildContext context, String name) {
  return name.isEmpty ? context.appLocalizations.unknown : name;
}

bool usageMatches(BuildContext context, UsageTotal item, SearchQuery query) {
  return query.matches([usageNameOf(context, item.name), item.name]);
}

class UsageFigure extends StatelessWidget {
  final Glyph glyph;
  final int bytes;

  const UsageFigure({super.key, required this.glyph, required this.bytes});

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        GlyphIcon(glyph, size: 12, color: color),
        Text(
          bytes.traffic.show,
          style: AppTextStyle.caption1.of(context).copyWith(color: color),
        ),
      ],
    );
  }
}

class UsageRow extends StatelessWidget {
  final UsageTotal item;
  final double share;
  final VoidCallback? onTap;

  const UsageRow({
    super.key,
    required this.item,
    required this.share,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListItem(
      onTap: onTap,
      minTileHeight: usageRowExtent,
      title: Text(
        usageNameOf(context, item.name),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Wrap(
            spacing: 12,
            children: [
              UsageFigure(glyph: AppGlyphs.arrowDown, bytes: item.download),
              UsageFigure(glyph: AppGlyphs.arrowUp, bytes: item.upload),
            ],
          ),
          LinearProgressIndicator(value: share),
        ],
      ),
      trailing: SizedBox(
        width: _usageTotalWidth,
        child: Text(
          item.total.traffic.show,
          maxLines: 1,
          textAlign: TextAlign.end,
          style: AppTextStyle.callout.of(context, emphasized: true),
        ),
      ),
    );
  }
}

class UsageSummary extends StatelessWidget {
  final int download;
  final int upload;

  const UsageSummary({super.key, required this.download, required this.upload});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 16,
        children: [
          Expanded(
            child: _SummaryFigure(
              label: appLocalizations.download,
              glyph: AppGlyphs.arrowDown,
              bytes: download,
            ),
          ),
          Expanded(
            child: _SummaryFigure(
              label: appLocalizations.upload,
              glyph: AppGlyphs.arrowUp,
              bytes: upload,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryFigure extends StatelessWidget {
  final String label;
  final Glyph glyph;
  final int bytes;

  const _SummaryFigure({
    required this.label,
    required this.glyph,
    required this.bytes,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            GlyphIcon(glyph, size: 14, color: color),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.footnote.of(context).copyWith(color: color),
              ),
            ),
          ],
        ),
        Text(
          bytes.traffic.show,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.title2.of(context, emphasized: true),
        ),
      ],
    );
  }
}

class UsageFindProcessNotice extends ConsumerWidget {
  const UsageFindProcessNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final off = ref.watch(
      patchClashConfigProvider.select(
        (state) => state.findProcessMode == FindProcessMode.off,
      ),
    );
    if (!off) {
      return const SizedBox.shrink();
    }
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 8, 6),
      child: Row(
        spacing: 12,
        children: [
          GlyphIcon(
            AppGlyphs.info,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          Expanded(
            child: Text(
              appLocalizations.usageFindProcessNotice,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.footnote
                  .of(context)
                  .copyWith(color: colorScheme.onSurface),
            ),
          ),
          TonalButton(
            size: TonalButtonSize.compact,
            label: appLocalizations.turnOn,
            onPressed: () => ref
                .read(patchClashConfigProvider.notifier)
                .update(
                  (state) =>
                      state.copyWith(findProcessMode: FindProcessMode.always),
                ),
          ),
        ],
      ),
    );
  }
}

class UsageList extends StatefulWidget {
  final List<UsageTotal> items;
  final Object scope;
  final double topPadding;
  final ValueChanged<UsageTotal>? onSelected;

  const UsageList({
    super.key,
    required this.items,
    required this.scope,
    this.topPadding = 0,
    this.onSelected,
  });

  @override
  State<UsageList> createState() => _UsageListState();
}

class _UsageListState extends State<UsageList>
    with ArrivalCacheExtentMixin<UsageList> {
  late final ScrollController _controller = sheetScrollController(context);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final scope = widget.scope;
    final onSelected = widget.onSelected;
    final largest = items.isEmpty ? 0 : items.first.total;
    final indexes = {
      for (final (index, item) in items.indexed) item.name: index,
    };
    return Scrollbar(
      controller: _controller,
      child: PrismListView(
        controller: _controller,
        padding: EdgeInsets.only(
          top: widget.topPadding,
          bottom: 16 + context.bottomInset,
        ),
        scrollCacheExtent: arrivalCacheExtent,
        itemCount: items.length,
        estimatedItemExtent: usageRowExtent,
        findChildIndexCallback: (key) =>
            key is ValueKey<String> ? indexes[key.value] : null,
        itemBuilder: (_, index) {
          final item = items[index];
          final share = largest == 0 ? 0.0 : item.total / largest;
          return MemoBuilder(
            key: ValueKey(item.name),
            inputs: [item, share, scope],
            builder: (_) => UsageRow(
              item: item,
              share: share,
              onTap: onSelected == null ? null : () => onSelected(item),
            ),
          );
        },
      ),
    );
  }
}

void showUsageBreakdown(
  BuildContext context, {
  required UsageRange range,
  required UsageTab tab,
  required String name,
}) {
  showSheet<void>(
    context: context,
    builder: (_) => Scaffold(
      title: usageNameOf(context, name),
      body: _UsageBreakdown(range: range, tab: tab, name: name),
    ),
  );
}

class _UsageBreakdown extends ConsumerWidget {
  final UsageRange range;
  final UsageTab tab;
  final String name;

  const _UsageBreakdown({
    required this.range,
    required this.tab,
    required this.name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(usageBreakdownProvider(range, tab, name));
    final items = breakdown.value;
    return NullStatusSwitcher(
      isLoading: items == null && !breakdown.hasError,
      isEmpty: items?.isEmpty ?? true,
      nullStatus: NullStatus(
        label: context.appLocalizations.noData,
        illustration: NullStatusIllustration.data,
      ),
      child: UsageList(
        items: items ?? const [],
        scope: (range, tab, name),
        topPadding: context.contentTopPadding,
      ),
    );
  }
}
