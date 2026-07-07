import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/risk_badge.dart';
import '../../data/symptom_repository.dart';
import '../../domain/symptom_history_entity.dart';
import '../../domain/symptom_result_entity.dart';

class SymptomHistoryScreen extends ConsumerStatefulWidget {
  final String petId;

  const SymptomHistoryScreen({super.key, required this.petId});

  @override
  ConsumerState<SymptomHistoryScreen> createState() => _SymptomHistoryScreenState();
}

class _SymptomHistoryScreenState extends ConsumerState<SymptomHistoryScreen> {
  late Future<List<SymptomHistoryEntity>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ref.read(symptomRepositoryProvider).getHistory(widget.petId);
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = ref.read(symptomRepositoryProvider).getHistory(widget.petId);
    });
  }

  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this symptom check?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.emergencyRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(symptomRepositoryProvider).deleteHistory(id);
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom History'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/pets/${widget.petId}/symptom-checker'),
            icon: const Icon(Icons.add),
            label: const Text('New Check'),
          ),
        ],
      ),
      body: FutureBuilder<List<SymptomHistoryEntity>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.emergencyRed),
                  const SizedBox(height: 16),
                  Text('Failed to load history', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }
          final history = snapshot.data ?? [];
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text('No symptom checks yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/pets/${widget.petId}/symptom-checker'),
                    child: const Text('Analyze Symptoms'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final item = history[i];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.emergencyRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    await _deleteItem(item.id);
                    return false;
                  },
                  child: Card(
                    child: ListTile(
                      leading: RiskBadge(riskLevel: item.riskLevel, size: 12),
                      title: Text(
                        item.symptoms,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_formatDate(item.createdAt)}  |  ${(item.confidence * 100).toStringAsFixed(0)}% confidence',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.isEmergency)
                            const Icon(Icons.warning, color: AppTheme.emergencyRed, size: 20),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textSecondary),
                            onPressed: () => _deleteItem(item.id),
                          ),
                        ],
                      ),
                      onTap: () {
                        final entity = SymptomResultEntity.fromJson({
                          ...?item.aiDiagnosis,
                          'risk_level': item.riskLevel,
                          'ai_provider': item.aiProvider,
                        });
                        context.push('/pets/${widget.petId}/symptom-result', extra: entity);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
