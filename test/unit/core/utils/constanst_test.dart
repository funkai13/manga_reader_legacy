import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/utils/constanst.dart';

void main() {
  group('Breakpoints', () {
    test('values', () {
      expect(Breakpoints.mobile, 600);
      expect(Breakpoints.tablet, 1024);
      expect(Breakpoints.desktop, 1440);
    });

    test('are strictly increasing', () {
      expect(Breakpoints.mobile, lessThan(Breakpoints.tablet));
      expect(Breakpoints.tablet, lessThan(Breakpoints.desktop));
    });
  });

  group('ApiConfig', () {
    test('apiUrl is a valid https URL', () {
      final uri = Uri.parse(ApiConfig.apiUrl);
      expect(uri.scheme, 'https');
      expect(uri.host, isNotEmpty);
    });
  });
}
