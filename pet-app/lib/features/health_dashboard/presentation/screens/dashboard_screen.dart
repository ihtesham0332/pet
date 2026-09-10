import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../health/presentation/providers/health_provider.dart';
import '../../../health/domain/reminder_entity.dart';
import '../../../health/domain/dashboard_summary_entity.dart';
import '../../../health/domain/weight_record_entity.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../../../pet/domain/pet_entity.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final pets = ref.read(petProvider).pets;
      if (pets.isNotEmpty) {
        ref.read(healthProvider.notifier).loadDashboard(petId: pets.first.id);
      } else {
        ref.read(healthProvider.notifier).loadDashboard();
      }
    });
  }

  Future<void> _refresh() async {
    final state = ref.read(healthProvider);
    await ref.read(healthProvider.notifier).loadDashboard(
      petId: state.selectedPetId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthProvider);
    final petState = ref.watch(petProvider);
    final pets = petState.pets;

    final selectedPet = pets.cast<PetEntity?>().firstWhere(
      (p) => p!.id == state.selectedPetId,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Reminder',
            onPressed: () => _showAddReminderSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: pets.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pets,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('Add a pet to see health data',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPetSelector(pets, state.selectedPetId),
                    if (selectedPet != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Text(
                          'Health overview for ${selectedPet.name}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    _buildStatsRow(state.summary),
                    const SizedBox(height: 24),
                    _buildWeightChart(state, pets),
                    const SizedBox(height: 24),
                    _buildUpcomingSection(state),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPetSelector(List<PetEntity> pets, String? selectedPetId) {
    if (pets.length <= 1 && selectedPetId != null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.pets,
                size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedPetId,
                  hint: const Text('Select a pet'),
                  items: pets.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (petId) {
                    if (petId != null) {
                      ref.read(healthProvider.notifier).selectPet(petId);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(DashboardSummaryEntity? summary) {
    final checkups = summary?.checkups ?? 0;
    final alerts = summary?.alerts ?? 0;
    final healthPct = summary?.healthPct ?? 100;
    final vetVisits = summary?.vetVisits ?? 0;

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatCard(
            icon: Icons.healing,
            label: 'Check-ups',
            value: checkups.toString(),
            color: AppTheme.infoBlue,
          ),
          _StatCard(
            icon: Icons.warning_amber,
            label: 'Alerts',
            value: alerts.toString(),
            color: alerts > 0 ? AppTheme.emergencyRed : AppTheme.accentOrange,
          ),
          _StatCard(
            icon: Icons.check_circle,
            label: 'Healthy',
            value: '$healthPct%',
            color: healthPct >= 70
                ? AppTheme.riskLow
                : healthPct >= 40
                    ? AppTheme.accentOrange
                    : AppTheme.emergencyRed,
          ),
          _StatCard(
            icon: Icons.calendar_today,
            label: 'Vet Visits',
            value: vetVisits.toString(),
            color: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart(DashboardState state, List<PetEntity> pets) {
    final selectedPet = pets.cast<PetEntity?>().firstWhere(
      (p) => p!.id == state.selectedPetId,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight Tracking',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: state.weightRecords.isEmpty
                  ? Center(
                      child: Text(
                        selectedPet != null
                            ? 'No weight records for ${selectedPet.name}.\nLog their first weight!'
                            : 'No weight records yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : _buildLineChart(state.weightRecords),
            ),
          ),
        ),
        if (state.selectedPetId != null) ...[
          const SizedBox(height: 8),
          _buildAddWeightButton(state.selectedPetId!),
        ],
      ],
    );
  }

  Widget _buildLineChart(List<WeightRecordEntity> records) {
    final sorted = List<WeightRecordEntity>.from(records)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final spots = sorted.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weightKg);
    }).toList();

    if (spots.isEmpty) return const SizedBox();

    final weights = sorted.map((r) => r.weightKg).toList();
    final minY = ((weights.reduce((a, b) => a < b ? a : b) - 1).clamp(0, double.infinity)).toDouble();
    final maxY = (weights.reduce((a, b) => a > b ? a : b) + 1).toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()} kg',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: ((spots.length / 4).ceilToDouble().clamp(1, double.infinity)).toDouble(),
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx >= 0 && idx < sorted.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('M/d').format(sorted[idx].measuredAt),
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryGreen,
            barWidth: 3,
            preventCurveOverShooting: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.primaryGreen,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddWeightButton(String petId) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAddWeightDialog(petId),
        icon: const Icon(Icons.monitor_weight, size: 18),
        label: const Text('Log Weight'),
      ),
    );
  }

  Future<void> _showAddWeightDialog(String petId) async {
    final weightCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Weight'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter weight';
                  final w = double.tryParse(v);
                  if (w == null || w <= 0 || w > 200) return 'Invalid weight';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && weightCtrl.text.isNotEmpty) {
      final w = double.parse(weightCtrl.text);
      final notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
      await ref.read(healthProvider.notifier).addWeightRecord(petId, w, notes: notes);
    }
  }

  Widget _buildUpcomingSection(DashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (state.reminders.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showAddReminderSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.isLoading)
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else if (state.error != null)
          _buildErrorState(state.error!)
        else if (state.reminders.isEmpty)
          _buildEmptyState()
        else
          ...state.reminders.map(
            (reminder) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ReminderCard(
                reminder: reminder,
                onComplete: () => ref
                    .read(healthProvider.notifier)
                    .completeReminder(reminder.id),
                onDelete: () =>
                    _confirmDelete(context, reminder),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              'Could not load reminders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAddReminderSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.event_note, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              Text(
                'No upcoming reminders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add vaccination, check-up, or medication reminders',
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showAddReminderSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ReminderEntity reminder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(healthProvider.notifier).deleteReminder(reminder.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddReminderSheet(),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderEntity reminder;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onComplete,
    required this.onDelete,
  });

  Color _typeColor() {
    switch (reminder.reminderType) {
      case 'vaccination':
        return AppTheme.accentOrange;
      case 'checkup':
        return AppTheme.infoBlue;
      case 'medication':
        return AppTheme.primaryGreen;
      case 'grooming':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon() {
    switch (reminder.reminderType) {
      case 'vaccination':
        return Icons.vaccines;
      case 'checkup':
        return Icons.medical_services;
      case 'medication':
        return Icons.medication;
      case 'grooming':
        return Icons.content_cut;
      default:
        return Icons.notifications;
    }
  }

  Color _statusChipColor() {
    if (reminder.isOverdue) return AppTheme.riskHigh;
    if (reminder.isUrgent) return AppTheme.warningYellow;
    return _typeColor().withOpacity(0.2);
  }

  Color _statusTextColor() {
    if (reminder.isOverdue) return AppTheme.riskHigh;
    if (reminder.isUrgent) return AppTheme.accentOrange;
    return _typeColor();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final color = _typeColor();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(_typeIcon(), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(reminder.scheduledDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (reminder.description != null &&
                        reminder.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          reminder.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusChipColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reminder.isOverdue
                          ? 'Overdue'
                          : reminder.isUrgent
                              ? 'Soon'
                              : reminder.daysUntil,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusTextColor(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onComplete,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.riskLow.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: AppTheme.riskLow,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.riskHigh.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppTheme.riskHigh,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddReminderSheet extends ConsumerStatefulWidget {
  const _AddReminderSheet();

  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'checkup';
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final hp = ref.read(healthProvider);
    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      'reminder_type': _type,
      'scheduled_date': _date.toIso8601String(),
    };
    if (hp.selectedPetId != null) {
      data['pet_id'] = hp.selectedPetId;
    }

    final ok = await ref.read(healthProvider.notifier).createReminder(data);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create reminder')),
      );
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Reminder',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Rabies Booster, Annual Check-up',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Additional notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'vaccination', child: Text('Vaccination')),
                DropdownMenuItem(value: 'checkup', child: Text('Check-up')),
                DropdownMenuItem(value: 'medication', child: Text('Medication')),
                DropdownMenuItem(value: 'grooming', child: Text('Grooming')),
                DropdownMenuItem(value: 'custom', child: Text('Custom')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Scheduled Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('MMM d, yyyy').format(_date),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 120,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
