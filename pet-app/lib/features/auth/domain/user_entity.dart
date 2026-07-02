class UserEntity {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String subscriptionTier;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.subscriptionTier = 'free',
    required this.createdAt,
  });
}
