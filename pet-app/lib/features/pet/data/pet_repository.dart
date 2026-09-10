import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/local_database_service.dart';
import '../../../core/network/token_storage.dart';

class PetRepository {
  final LocalDatabaseService _db;
  final TokenStorage _storage;

  PetRepository(this._db, this._storage);

  Future<Map<String, dynamic>> createPet(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) throw Exception('Not logged in');

    final pet = Map<String, dynamic>.from(data);
    pet['id'] = const Uuid().v4();
    pet['user_id'] = userId;
    pet['created_at'] = DateTime.now().toIso8601String();
    pet['updated_at'] = DateTime.now().toIso8601String();

    await _db.savePet(pet);
    return pet;
  }

  Future<List<dynamic>> listPets() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) throw Exception('Not logged in');

    final pets = await _db.getPets();
    return pets.where((p) => p['user_id'] == userId).toList();
  }

  Future<Map<String, dynamic>> getPet(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final pet = await _db.getPet(id);
    if (pet == null) throw Exception('Pet not found');
    return pet;
  }

  Future<Map<String, dynamic>> updatePet(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final pet = await _db.getPet(id);
    if (pet == null) throw Exception('Pet not found');

    final updatedPet = Map<String, dynamic>.from(pet)..addAll(data);
    updatedPet['updated_at'] = DateTime.now().toIso8601String();
    
    await _db.savePet(updatedPet);
    return updatedPet;
  }

  Future<void> deletePet(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _db.deletePet(id);
  }
}

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository(LocalDatabaseService(), TokenStorage());
});
