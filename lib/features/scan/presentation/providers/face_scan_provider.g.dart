// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'face_scan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FaceScan)
final faceScanProvider = FaceScanProvider._();

final class FaceScanProvider
    extends $NotifierProvider<FaceScan, FaceScanState> {
  FaceScanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'faceScanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$faceScanHash();

  @$internal
  @override
  FaceScan create() => FaceScan();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FaceScanState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FaceScanState>(value),
    );
  }
}

String _$faceScanHash() => r'59771819e0051ab48ae401b22c22d93a0389b26d';

abstract class _$FaceScan extends $Notifier<FaceScanState> {
  FaceScanState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FaceScanState, FaceScanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FaceScanState, FaceScanState>,
              FaceScanState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
