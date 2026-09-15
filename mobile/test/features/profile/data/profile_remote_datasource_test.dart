import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;
  late ProfileRemoteDataSourceImpl dataSource;

  setUp(() {
    client = MockApiClient();
    dataSource = ProfileRemoteDataSourceImpl(client);
  });

  group('updateProfile', () {
    test('sends non-null fields to PATCH /profile and parses the returned user',
        () async {
      when(
        () => client.patch<Map<String, dynamic>>(
          ApiConstants.profile,
          data: {
            'userName': 'Jane Bloom',
            'userPhone': '+1234567890',
            'avatarUrl': 'https://example.com/avatar.png',
          },
        ),
      ).thenAnswer(
        (_) async => {
          'message': 'Profile updated successfully',
          'user': {
            'id': '11111111-1111-4111-8111-111111111111',
            'email': 'jane@example.com',
            'userName': 'Jane Bloom',
            'userPhone': '+1234567890',
            'avatarUrl': 'https://example.com/avatar.png',
            'createdAt': '2026-01-01T00:00:00.000Z',
          },
        },
      );

      final user = await dataSource.updateProfile(
        userName: 'Jane Bloom',
        userPhone: '+1234567890',
        avatarUrl: 'https://example.com/avatar.png',
      );

      expect(user.userName, 'Jane Bloom');
      expect(user.userPhone, '+1234567890');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.displayName, 'Jane Bloom');
    });

    test('omits null fields from payload', () async {
      when(
        () => client.patch<Map<String, dynamic>>(
          ApiConstants.profile,
          data: {'userName': 'Jane Only'},
        ),
      ).thenAnswer(
        (_) async => {
          'message': 'Profile updated successfully',
          'user': {
            'id': '11111111-1111-4111-8111-111111111111',
            'email': 'jane@example.com',
            'userName': 'Jane Only',
            'createdAt': '2026-01-01T00:00:00.000Z',
          },
        },
      );

      final user = await dataSource.updateProfile(userName: 'Jane Only');

      expect(user.userName, 'Jane Only');
      expect(user.userPhone, isNull);
      expect(user.avatarUrl, isNull);
    });
  });
}
