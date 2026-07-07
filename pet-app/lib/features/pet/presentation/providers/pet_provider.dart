import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/pet_repository.dart';
import '../../domain/pet_entity.dart';

class PetListState {
  final bool isLoading;
  final List<PetEntity> pets;
  final String? error;

  const PetListState({
    this.isLoading = false,
    this.pets = const [],
    this.error,
  });

  factory PetListState.initial() => const PetListState();

  PetListState copyWith({bool? isLoading, List<PetEntity>? pets, String? error}) {
    return PetListState(
      isLoading: isLoading ?? this.isLoading,
      pets: pets ?? this.pets,
      error: error,
    );
  }
}

class PetProvider extends StateNotifier<PetListState> {
  final PetRepository _repository;

  PetProvider(this._repository) : super(PetListState.initial());

  static PetEntity? _tryFromJson(Map<String, dynamic> json) {
    try {
      final raw = json;
      final id = raw['id'];
      final userId = raw['user_id'];
      final name = raw['name'];
      final species = raw['species'];
      if (id == null || userId == null || name == null || species == null) {
        return null;
      }
      return PetEntity(
        id: id is String ? id : id.toString(),
        userId: userId is String ? userId : userId.toString(),
        name: name is String ? name : name.toString(),
        species: species is String ? species : species.toString(),
        breed: raw['breed'] as String?,
        dateOfBirth: _parseDate(raw['date_of_birth']),
        weightKg: _parseWeight(raw['weight_kg']),
        medicalHistory: raw['medical_history'] as String?,
        avatarUrl: raw['avatar_url'] as String?,
        createdAt: _parseDateTime(raw['created_at']),
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static double? _parseWeight(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> loadPets() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.listPets();
      final pets = <PetEntity>[];
      for (final j in data) {
        if (j is Map<String, dynamic>) {
          final pet = _tryFromJson(j);
          if (pet != null) pets.add(pet);
        }
      }
      state = state.copyWith(isLoading: false, pets: pets);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createPet(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.createPet(data);
      final pet = _tryFromJson(result);
      if (pet == null) {
        state = state.copyWith(isLoading: false, error: 'Failed to parse pet response');
        return false;
      }
      state = state.copyWith(isLoading: false, pets: [...state.pets, pet]);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deletePet(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deletePet(id);
      state = state.copyWith(
        isLoading: false,
        pets: state.pets.where((p) => p.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final petProvider = StateNotifierProvider<PetProvider, PetListState>((ref) {
  return PetProvider(ref.read(petRepositoryProvider));
});
