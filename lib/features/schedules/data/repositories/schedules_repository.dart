import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:tripee_app/core/constants/api_constants.dart';
import 'package:tripee_app/core/errors/exceptions.dart';
import 'package:tripee_app/core/network/http_client.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_detail_model.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_model.dart';

abstract class ISchedulesRepository {
  Future<PaginatedSchedulesModel> getSchedules({
    required int page,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  Future<ScheduleDetailModel> getScheduleById(String id);
}

class SchedulesRepository implements ISchedulesRepository {
  final Dio _dio;

  SchedulesRepository({Dio? dio}) : _dio = dio ?? HttpClient.instance;

  @override
  Future<PaginatedSchedulesModel> getSchedules({
    required int page,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': ApiConstants.pageSize,
      };

      if (dateFrom != null) {
        queryParams['date_from'] = DateFormat('yyyy-MM-dd').format(dateFrom);
      }
      if (dateTo != null) {
        queryParams['date_to'] = DateFormat('yyyy-MM-dd').format(dateTo);
      }

      final response = await _dio.get(
        ApiConstants.schedulesEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return PaginatedSchedulesModel.fromJson(data);
        }
        throw const ServerException(message: 'Formato de resposta inesperado.');
      }

      throw ServerException(statusCode: response.statusCode);
    } on DioException catch (e) {
      throw HttpClient.handleDioException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: $e');
    }
  }

  @override
  Future<ScheduleDetailModel> getScheduleById(String id) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.schedulesEndpoint}/$id',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return ScheduleDetailModel.fromJson(data);
        }
        throw const ServerException(message: 'Formato de resposta inesperado.');
      }

      throw ServerException(statusCode: response.statusCode);
    } on DioException catch (e) {
      throw HttpClient.handleDioException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: $e');
    }
  }
}
