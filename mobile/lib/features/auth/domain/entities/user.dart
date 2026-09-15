/// An authenticated account.
///
/// Mirrors the backend's `SafeUser` — the Prisma `User` row with `passwordHash`
/// stripped. Pure Dart with no JSON concerns: serialisation lives in
/// `data/models/user_model.dart`, so the domain never depends on the wire
/// format.
class User {
  const User({
    required this.id,
    required this.email,
    required this.createdAt,
    this.userName,
    this.userPhone,
    this.avatarUrl,
  });

  /// UUID assigned by the backend.
  final String id;

  final String email;

  /// When the account was created.
  final DateTime createdAt;

  final String? userName;
  final String? userPhone;
  final String? avatarUrl;

  /// A display name preferred from [userName], falling back to the email local
  /// part, capitalised. Empty when neither is available.
  String get displayName {
    if (userName != null && userName!.trim().isNotEmpty) {
      return userName!.trim();
    }
    final local = email.split('@').first;
    if (local.isEmpty) return '';
    return '${local[0].toUpperCase()}${local.substring(1)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          id == other.id &&
          email == other.email &&
          createdAt == other.createdAt &&
          userName == other.userName &&
          userPhone == other.userPhone &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode =>
      Object.hash(id, email, createdAt, userName, userPhone, avatarUrl);

  @override
  String toString() =>
      'User(id: $id, email: $email, userName: $userName, userPhone: $userPhone, avatarUrl: $avatarUrl)';
}
