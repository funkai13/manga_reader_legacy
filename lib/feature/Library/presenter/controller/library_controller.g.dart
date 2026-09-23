// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LibraryController)
const libraryControllerProvider = LibraryControllerFamily._();

final class LibraryControllerProvider
    extends $AsyncNotifierProvider<LibraryController, List<CategoryEntity>> {
  const LibraryControllerProvider._(
      {required LibraryControllerFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'libraryControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$libraryControllerHash();

  @override
  String toString() {
    return r'libraryControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LibraryController create() => LibraryController();

  @override
  bool operator ==(Object other) {
    return other is LibraryControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$libraryControllerHash() => r'c96d3a0c7a5729c0bec319de9cda0dd1e55858f7';

final class LibraryControllerFamily extends $Family
    with
        $ClassFamilyOverride<
            LibraryController,
            AsyncValue<List<CategoryEntity>>,
            List<CategoryEntity>,
            FutureOr<List<CategoryEntity>>,
            String> {
  const LibraryControllerFamily._()
      : super(
          retry: null,
          name: r'libraryControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  LibraryControllerProvider call(
    String type,
  ) =>
      LibraryControllerProvider._(argument: type, from: this);

  @override
  String toString() => r'libraryControllerProvider';
}

abstract class _$LibraryController
    extends $AsyncNotifier<List<CategoryEntity>> {
  late final _$args = ref.$arg as String;
  String get type => _$args;

  FutureOr<List<CategoryEntity>> build(
    String type,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      _$args,
    );
    final ref = this.ref
        as $Ref<AsyncValue<List<CategoryEntity>>, List<CategoryEntity>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<CategoryEntity>>, List<CategoryEntity>>,
        AsyncValue<List<CategoryEntity>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
