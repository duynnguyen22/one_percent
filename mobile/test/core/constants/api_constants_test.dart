import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_constants.dart';

void main() {
  group('mediaUrl', () {
    test('prefixes a backend-stored path with the API base URL', () {
      expect(
        ApiConstants.mediaUrl('/uploads/avatars/a.jpg'),
        '${ApiConstants.baseUrl}/uploads/avatars/a.jpg',
      );
    });

    test('leaves absolute URLs untouched', () {
      expect(
        ApiConstants.mediaUrl('https://cdn.example.com/a.jpg'),
        'https://cdn.example.com/a.jpg',
      );
    });
  });
}
