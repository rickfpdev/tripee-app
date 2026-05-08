import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_model.dart';
import 'package:tripee_app/features/schedules/data/repositories/schedules_repository.dart';

enum LoadingState { idle, loading, loadingMore, loaded, error }

class SchedulesGrouped {
  final String label;
  final DateTime date;
  final List<ScheduleModel> items;

  const SchedulesGrouped({
    required this.label,
    required this.date,
    required this.items,
  });
}

class SchedulesProvider extends ChangeNotifier {
  final ISchedulesRepository _repository;

  SchedulesProvider({ISchedulesRepository? repository})
      : _repository = repository ?? SchedulesRepository();

  // State
  LoadingState _state = LoadingState.idle;
  String? _errorMessage;
  final List<ScheduleModel> _items = [];
  int _currentPage = 1;
  int _totalPages = 1;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _hasAppliedFilter = false;

  // Getters
  LoadingState get state => _state;
  String? get errorMessage => _errorMessage;
  List<ScheduleModel> get items => List.unmodifiable(_items);
  bool get hasMore => _currentPage < _totalPages;
  bool get hasAppliedFilter => _hasAppliedFilter;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  String get filterLabel {
    if (!_hasAppliedFilter || (_dateFrom == null && _dateTo == null)) {
      return 'Período';
    }
    final fmt = DateFormat('dd/MM/yy');
    if (_dateFrom != null && _dateTo != null) {
      return '${fmt.format(_dateFrom!)} – ${fmt.format(_dateTo!)}';
    }
    if (_dateFrom != null) return 'A partir de ${fmt.format(_dateFrom!)}';
    return 'Até ${fmt.format(_dateTo!)}';
  }

  List<SchedulesGrouped> get groupedItems {
    if (_items.isEmpty) return [];

    final Map<String, List<ScheduleModel>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final item in _items) {
      final itemDate = DateTime(
        item.scheduleAt.year,
        item.scheduleAt.month,
        item.scheduleAt.day,
      );

      String label;
      if (itemDate == today) {
        label = 'Hoje · ${DateFormat('d MMM, yyyy', 'pt_BR').format(itemDate)}';
      } else if (itemDate == yesterday) {
        label =
            'Ontem · ${DateFormat('d MMM, yyyy', 'pt_BR').format(itemDate)}';
      } else {
        label =
            '${DateFormat('EEEE', 'pt_BR').format(itemDate)[0].toUpperCase()}${DateFormat('EEEE', 'pt_BR').format(itemDate).substring(1)} · ${DateFormat('d MMM, yyyy', 'pt_BR').format(itemDate)}';
      }

      groups.putIfAbsent(label, () => []).add(item);
    }

    return groups.entries
        .map((e) => SchedulesGrouped(
              label: e.key,
              date: e.value.first.scheduleAt,
              items: e.value,
            ))
        .toList();
  }

  // Actions

  Future<void> loadInitial() async {
    if (_state == LoadingState.loading) return;
    _state = LoadingState.loading;
    _errorMessage = null;
    _items.clear();
    _currentPage = 1;
    notifyListeners();

    await _fetchPage(1);
  }

  Future<void> loadMore() async {
    if (_state == LoadingState.loadingMore || _state == LoadingState.loading) {
      return;
    }
    if (!hasMore) return;

    _state = LoadingState.loadingMore;
    notifyListeners();

    await _fetchPage(_currentPage + 1);
  }

  Future<void> applyDateFilter({DateTime? dateFrom, DateTime? dateTo}) async {
    _dateFrom = dateFrom;
    _dateTo = dateTo;
    _hasAppliedFilter = dateFrom != null || dateTo != null;
    await loadInitial();
  }

  Future<void> clearFilter() async {
    _dateFrom = null;
    _dateTo = null;
    _hasAppliedFilter = false;
    await loadInitial();
  }

  Future<void> retry() async {
    await loadInitial();
  }

  Future<void> _fetchPage(int page) async {
    try {
      final result = await _repository.getSchedules(
        page: page,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

      _items.addAll(result.items);
      _currentPage = result.currentPage;
      _totalPages = result.totalPages;
      _state = LoadingState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = LoadingState.error;
    }

    notifyListeners();
  }
}
