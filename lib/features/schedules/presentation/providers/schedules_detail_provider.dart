import 'package:flutter/foundation.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_detail_model.dart';
import 'package:tripee_app/features/schedules/data/repositories/schedules_repository.dart';

enum DetailLoadingState { idle, loading, loaded, error }

class ScheduleDetailProvider extends ChangeNotifier {
  final ISchedulesRepository _repository;

  ScheduleDetailProvider({ISchedulesRepository? repository})
      : _repository = repository ?? SchedulesRepository();

  DetailLoadingState _state = DetailLoadingState.idle;
  ScheduleDetailModel? _detail;
  String? _errorMessage;

  DetailLoadingState get state => _state;
  ScheduleDetailModel? get detail => _detail;
  String? get errorMessage => _errorMessage;

  Future<void> loadDetail(String id) async {
    _state = DetailLoadingState.loading;
    _errorMessage = null;
    _detail = null;
    notifyListeners();

    try {
      _detail = await _repository.getScheduleById(id);
      _state = DetailLoadingState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = DetailLoadingState.error;
    }

    notifyListeners();
  }

  Future<void> retry(String id) async {
    await loadDetail(id);
  }
}
