import 'package:flutter/material.dart';
import 'package:tripee_app/core/theme/app_theme.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_model.dart';
import 'package:tripee_app/features/schedules/presentation/widgets/status_badget.dart';

class ScheduleListItem extends StatelessWidget {
  final ScheduleModel schedule;
  final VoidCallback onTap;

  const ScheduleListItem({
    super.key,
    required this.schedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule.timeLabel, style: AppTextStyles.time),
                    const SizedBox(height: 8),
                    _AddressRow(
                      address: schedule.startAddress,
                      isOrigin: true,
                    ),
                    const SizedBox(height: 4),
                    _AddressRow(
                      address: schedule.endAddress,
                      isOrigin: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(status: schedule.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final String address;
  final bool isOrigin;

  const _AddressRow({required this.address, required this.isOrigin});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            isOrigin ? Icons.radio_button_checked : Icons.location_on_outlined,
            size: 14,
            color: AppColors.iconOrigin,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            address,
            style: AppTextStyles.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}