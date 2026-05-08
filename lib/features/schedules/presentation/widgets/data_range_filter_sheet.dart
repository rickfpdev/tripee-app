import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:tripee_app/core/theme/app_theme.dart';

class DateRangeFilterSheet extends StatefulWidget {
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;

  const DateRangeFilterSheet({
    super.key,
    this.initialDateFrom,
    this.initialDateTo,
  });

  @override
  State<DateRangeFilterSheet> createState() => _DateRangeFilterSheetState();
}

class _DateRangeFilterSheetState extends State<DateRangeFilterSheet> {
  DateTime? _selectedFrom;
  DateTime? _selectedTo;
  late final DateRangePickerController _controller;

  @override
  void initState() {
    super.initState();
    _selectedFrom = widget.initialDateFrom;
    _selectedTo = widget.initialDateTo;
    _controller = DateRangePickerController();

    if (_selectedFrom != null && _selectedTo != null) {
      _controller.selectedRange = PickerDateRange(_selectedFrom, _selectedTo);
    } else if (_selectedFrom != null) {
      _controller.selectedRange = PickerDateRange(_selectedFrom, null);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _rangeLabel {
    if (_selectedFrom == null && _selectedTo == null) {
      return 'Data inicial - Data final';
    }
    final months = [
      '',
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    String fmt(DateTime d) => '${months[d.month]} ${d.day}';
    if (_selectedFrom != null && _selectedTo != null) {
      return '${fmt(_selectedFrom!)} – ${fmt(_selectedTo!)}';
    }
    if (_selectedFrom != null) return fmt(_selectedFrom!);
    return fmt(_selectedTo!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data inicial - Data final',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _rangeLabel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SfDateRangePicker(
            controller: _controller,
            selectionMode: DateRangePickerSelectionMode.range,
            maxDate: DateTime.now(),
            monthViewSettings: const DateRangePickerMonthViewSettings(
              firstDayOfWeek: 7,
            ),
            selectionColor: AppColors.primary,
            startRangeSelectionColor: AppColors.primary,
            endRangeSelectionColor: AppColors.primary,
            rangeSelectionColor: AppColors.primary.withOpacity(0.1),
            todayHighlightColor: AppColors.primary,
            onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
              if (args.value is PickerDateRange) {
                final range = args.value as PickerDateRange;
                setState(() {
                  _selectedFrom = range.startDate;
                  _selectedTo = range.endDate;
                });
              }
            },
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, _ClearResult()),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _canSave ? _onSave : null,
                  child: Text(
                    'Salvar',
                    style: TextStyle(
                      color: _canSave ? AppColors.primary : AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSave => _selectedFrom != null;

  void _onSave() {
    Navigator.pop(
      context,
      _DateRangeResult(dateFrom: _selectedFrom, dateTo: _selectedTo),
    );
  }
}

class _DateRangeResult {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  const _DateRangeResult({this.dateFrom, this.dateTo});
}

class _ClearResult {}

Future<void> showDateRangeFilter(
  BuildContext context, {
  DateTime? initialDateFrom,
  DateTime? initialDateTo,
  required void Function(DateTime? from, DateTime? to) onApply,
  required VoidCallback onClear,
}) async {
  final result = await showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DateRangeFilterSheet(
      initialDateFrom: initialDateFrom,
      initialDateTo: initialDateTo,
    ),
  );

  if (result is _DateRangeResult) {
    onApply(result.dateFrom, result.dateTo);
  } else if (result is _ClearResult) {
    onClear();
  }
}
