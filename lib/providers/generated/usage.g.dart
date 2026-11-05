// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../usage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UsageRevision)
final usageRevisionProvider = UsageRevisionProvider._();

final class UsageRevisionProvider
    extends $NotifierProvider<UsageRevision, int> {
  UsageRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usageRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usageRevisionHash();

  @$internal
  @override
  UsageRevision create() => UsageRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$usageRevisionHash() => r'66d9c86294d036dd92c06f7afcfe2416ad2f01ad';

abstract class _$UsageRevision extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(usageRecorder)
final usageRecorderProvider = UsageRecorderProvider._();

final class UsageRecorderProvider
    extends $FunctionalProvider<UsageRecorder, UsageRecorder, UsageRecorder>
    with $Provider<UsageRecorder> {
  UsageRecorderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usageRecorderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usageRecorderHash();

  @$internal
  @override
  $ProviderElement<UsageRecorder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UsageRecorder create(Ref ref) {
    return usageRecorder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UsageRecorder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UsageRecorder>(value),
    );
  }
}

String _$usageRecorderHash() => r'10a2ed26e17dcdc3077fed79c038cacebe852d4b';

@ProviderFor(usageOverview)
final usageOverviewProvider = UsageOverviewFamily._();

final class UsageOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<UsageOverview>,
          UsageOverview,
          FutureOr<UsageOverview>
        >
    with $FutureModifier<UsageOverview>, $FutureProvider<UsageOverview> {
  UsageOverviewProvider._({
    required UsageOverviewFamily super.from,
    required UsageRange super.argument,
  }) : super(
         retry: null,
         name: r'usageOverviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$usageOverviewHash();

  @override
  String toString() {
    return r'usageOverviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UsageOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UsageOverview> create(Ref ref) {
    final argument = this.argument as UsageRange;
    return usageOverview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UsageOverviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$usageOverviewHash() => r'afcf7a88d0c753986d25ea9473b8389a8d45a14e';

final class UsageOverviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UsageOverview>, UsageRange> {
  UsageOverviewFamily._()
    : super(
        retry: null,
        name: r'usageOverviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UsageOverviewProvider call(UsageRange range) =>
      UsageOverviewProvider._(argument: range, from: this);

  @override
  String toString() => r'usageOverviewProvider';
}

/// What [name], an app on the apps tab or a domain on the domains tab, spent
/// its traffic on.

@ProviderFor(usageBreakdown)
final usageBreakdownProvider = UsageBreakdownFamily._();

/// What [name], an app on the apps tab or a domain on the domains tab, spent
/// its traffic on.

final class UsageBreakdownProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UsageTotal>>,
          List<UsageTotal>,
          FutureOr<List<UsageTotal>>
        >
    with $FutureModifier<List<UsageTotal>>, $FutureProvider<List<UsageTotal>> {
  /// What [name], an app on the apps tab or a domain on the domains tab, spent
  /// its traffic on.
  UsageBreakdownProvider._({
    required UsageBreakdownFamily super.from,
    required (UsageRange, UsageTab, String) super.argument,
  }) : super(
         retry: null,
         name: r'usageBreakdownProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$usageBreakdownHash();

  @override
  String toString() {
    return r'usageBreakdownProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<UsageTotal>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UsageTotal>> create(Ref ref) {
    final argument = this.argument as (UsageRange, UsageTab, String);
    return usageBreakdown(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is UsageBreakdownProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$usageBreakdownHash() => r'f50722e80abc127d0d4df73f2bb46c636407dcc9';

/// What [name], an app on the apps tab or a domain on the domains tab, spent
/// its traffic on.

final class UsageBreakdownFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<UsageTotal>>,
          (UsageRange, UsageTab, String)
        > {
  UsageBreakdownFamily._()
    : super(
        retry: null,
        name: r'usageBreakdownProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What [name], an app on the apps tab or a domain on the domains tab, spent
  /// its traffic on.

  UsageBreakdownProvider call(UsageRange range, UsageTab tab, String name) =>
      UsageBreakdownProvider._(argument: (range, tab, name), from: this);

  @override
  String toString() => r'usageBreakdownProvider';
}
