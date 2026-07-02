class PetEntity {
  final String id;
  final String userId;
  final String name;
  final String species;
  final String? breed;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final String? medicalHistory;
  final String? avatarUrl;
  final DateTime createdAt;

  const PetEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    this.dateOfBirth,
    this.weightKg,
    this.medicalHistory,
    this.avatarUrl,
    required this.createdAt,
  });

  int get age {
    if (dateOfBirth == null) return 0;
    return DateTime.now().year - dateOfBirth!.year;
  }

  String get ageGroup {
    if (species == 'cat') {
      if (age > 10) return 'Senior';
      if (age < 1) return 'Kitten';
      return 'Adult';
    }
    if (age > 8) return 'Senior';
    if (age < 1) return 'Puppy';
    return 'Adult';
  }
}
