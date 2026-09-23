import 'package:rar/rar.dart';

/// Stands in for package:rar's native side. [onExtract] writes the files the
/// "archive" contains into the destination folder.
class FakeRarPlatform extends RarPlatform {
  void Function(String destination)? onExtract;
  Map<String, dynamic> result = {'success': true, 'message': 'ok'};
  Object? error;
  final extractedFrom = <String>[];

  @override
  Future<Map<String, dynamic>> extractRarFile({
    required String rarFilePath,
    required String destinationPath,
    String? password,
  }) async {
    extractedFrom.add(rarFilePath);
    if (error != null) throw error!;
    onExtract?.call(destinationPath);
    return result;
  }
}
