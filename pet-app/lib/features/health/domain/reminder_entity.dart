import 'package:equatable/equatable.dart';

class ReminderEntity extends Equatable {
  final String id;
  final String userId;
  final String? petId;
  final String title;
  final String? description;
  final String reminderType;
  final DateTime scheduledDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReminderEntity({
    required this.id,
    required this.userId,
    this.petId,
    required this.title,
    this.description,
    required this.reminderType,
    required this.scheduledDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  String get daysUntil {
    final diff = scheduledDate.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return '${diff.inDays} days';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months';
    return '${(diff.inDays / 365).floor()} years';
  }

  bool get isUrgent {
    final diff = scheduledDate.difference(DateTime.now());
    return diff.inDays <= 7 && !diff.isNegative;
  }

  bool get isOverdue => scheduledDate.isBefore(DateTime.now());

  String get typeLabel {
    switch (reminderType) {
      case 'vaccination':
        return 'Vaccination';
      case 'checkup':
        return 'Check-up';
      case 'medication':
        return 'Medication';
      case 'grooming':
        return 'Grooming';
      default:
        return reminderType;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        petId,
        title,
        description,
        reminderType,
        scheduledDate,
        status,
        createdAt,
        updatedAt,
      ];
}
