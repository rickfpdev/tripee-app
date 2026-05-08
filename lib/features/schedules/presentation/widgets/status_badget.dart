import 'package:flutter/material.dart';
import 'package:tripee_app/core/theme/app_theme.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_model.dart';

class StatusBadge extends StatelessWidget {
  final ScheduleStatus status;
  final bool filled;

  const StatusBadge({
    super.key,
    required this.status,
    this.filled = false,
  });

  Color get _color {
    switch (status) {
      case ScheduleStatus.realizada:
        return AppColors.statusRealizada;
      case ScheduleStatus.cancelada:
        return AppColors.statusCancelada;
      case ScheduleStatus.pendente:
        return AppColors.statusPendente;
      case ScheduleStatus.emAndamento:
        return AppColors.primary;
      case ScheduleStatus.concluida:
        return AppColors.statusConcluida;
      case ScheduleStatus.unknown:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withOpacity(0.3)),
        ),
        child: Text(
          status.label,
          style: AppTextStyles.statusLabel.copyWith(
            color: _color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Text(
      status.label,
      style: AppTextStyles.statusLabel.copyWith(color: _color),
    );
  }
}
