import 'package:flutter/material.dart';
import 'package:pet_health_assistant/core/theme/app_theme.dart';

class RiskBadge extends StatelessWidget {
  final String riskLevel;
  final double size;

  const RiskBadge({
    super.key,
    required this.riskLevel,
    this.size = 12,
  });

  Color get _color {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return AppTheme.riskLow;
      case 'medium':
        return AppTheme.riskMedium;
      case 'high':
        return AppTheme.riskHigh;
      case 'critical':
        return AppTheme.riskCritical;
      default:
        return Colors.grey;
    }
  }

  IconData get _icon {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Icons.check_circle;
      case 'medium':
        return Icons.info;
      case 'high':
        return Icons.warning;
      case 'critical':
        return Icons.dangerous;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_icon, size: size, color: Colors.white),
      label: Text(
        riskLevel.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: _color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
