import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockProfileRemoteDataSource remote;
  late MockAuthLocalDataSource local;
  late MockNetworkInfo network;
  late ProfileRepositoryImpl repository;

  final user = buildUserModel(
    userName: 'Jane',
    userPhone: '123456',
    avatarUrl: 'https://img.com/pic.jpg',
  );

  setUpAll(registerFallbacks);

  setUp(() {
    remote = MockProfileRemoteDataSource();
    local = MockAuthLocalDataSource();
    network = MockNetworkInfo();
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => local.cacheUser(any())).thenAnswer((_) async {});
    repository = ProfileRepositoryImpl(
      remoteDataSource: remote,
      authLocalDataSource: local,
      networkInfo: network,
    );
  });

  group('updateProfile', () {
    test('updates remote and caches updated user in local storage on success',
        () async {
      when(() => remote.updateProfile(
            userName: 'Jane',
            userPhone: '123456',
            avatarUrl: 'https://img.com/pic.jpg',
          )).thenAnswer((_) async => user);

      final result = await repository.updateProfile(
        userName: 'Jane',
        userPhone: '123456',
        avatarUrl: 'https://img.com/pic.jpg',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, user);
      verify(() => local.cacheUser(user)).called(1);
    });

    test('short-circuits when offline with NetworkFailure', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repository.updateProfile(userName: 'Jane');

      expect(result.failureOrNull, isA<NetworkFailure>());
      verifyNever(() => remote.updateProfile(userName: any(named: 'userName')));
      verifyNever(() => local.cacheUser(any()));
    });

    test('maps AppException onto Failure', () async {
      when(() => remote.updateProfile(userName: 'Jane'))
          .thenThrow(const ServerException('Internal server error', statusCode: 500));

      final result = await repository.updateProfile(userName: 'Jane');

      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });
}
