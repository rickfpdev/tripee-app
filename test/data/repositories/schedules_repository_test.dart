import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tripee_app/core/constants/api_constants.dart';
import 'package:tripee_app/core/errors/exceptions.dart';
import 'package:tripee_app/features/schedules/data/repositories/schedules_repository.dart';

import '../../helpers/fixtures.dart';


void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late SchedulesRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    // Adiciona o mesmo interceptor de erro que o HttpClient usa em produção
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          if (e.type == DioExceptionType.badResponse) {
            final statusCode = e.response?.statusCode;
            if (statusCode == 404) {
              handler.reject(DioException(
                requestOptions: e.requestOptions,
                error: const NotFoundException(),
                type: e.type,
                response: e.response,
              ));
            } else {
              handler.reject(DioException(
                requestOptions: e.requestOptions,
                error: ServerException(statusCode: statusCode),
                type: e.type,
                response: e.response,
              ));
            }
          } else {
            handler.next(e);
          }
        },
      ),
    );
    dioAdapter = DioAdapter(dio: dio);
    repository = SchedulesRepository(dio: dio);
  });

  group('getSchedules', () {
    test('chama o endpoint correto com page e limit=15', () async {
      dioAdapter.onGet(
        ApiConstants.schedulesEndpoint,
        queryParameters: {'page': 1, 'limit': 15},
        (server) => server.reply(200, scheduleListFixture),
      );

      final result = await repository.getSchedules(page: 1);

      expect(result.items.length, 2);
      expect(result.currentPage, 1);
      expect(result.totalPages, 3);
    });

    test('inclui date_from e date_to quando fornecidos', () async {
      dioAdapter.onGet(
        ApiConstants.schedulesEndpoint,
        queryParameters: {
          'page': 1,
          'limit': 15,
          'date_from': '2026-05-01',
          'date_to': '2026-05-08',
        },
        (server) => server.reply(200, scheduleListFixture),
      );

      final result = await repository.getSchedules(
        page: 1,
        dateFrom: DateTime(2026, 5, 1),
        dateTo: DateTime(2026, 5, 8),
      );

      expect(result.items, isNotEmpty);
    });

    test('não inclui date_from/date_to quando não fornecidos', () async {
      dioAdapter.onGet(
        ApiConstants.schedulesEndpoint,
        queryParameters: {'page': 2, 'limit': 15},
        (server) => server.reply(200, {
          ...scheduleListFixture,
          'page': 2,
        }),
      );

      final result = await repository.getSchedules(page: 2);
      expect(result.currentPage, 2);
    });


    test('lança ServerException em erro 500', () async {
      dioAdapter.onGet(
        ApiConstants.schedulesEndpoint,
        queryParameters: {'page': 1, 'limit': 15},
        (server) => server.reply(500, {'message': 'Internal Server Error'}),
      );

      expect(
        () => repository.getSchedules(page: 1),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('getScheduleById', () {
    test('chama o endpoint correto com o id', () async {
      dioAdapter.onGet(
        '${ApiConstants.schedulesEndpoint}/abc-123',
        (server) => server.reply(200, scheduleDetailFixture),
      );

      final result = await repository.getScheduleById('abc-123');

      expect(result.origin.city, 'São Paulo');
      expect(result.driver!.name, 'Carlos Silva');
    });

    test('lança NotFoundException em erro 404', () async {
      dioAdapter.onGet(
        '${ApiConstants.schedulesEndpoint}/id-inexistente',
        (server) => server.reply(404, {'message': 'Not found'}),
      );

      expect(
        () => repository.getScheduleById('id-inexistente'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('lança ServerException em erro 500', () async {
      dioAdapter.onGet(
        '${ApiConstants.schedulesEndpoint}/abc-123',
        (server) => server.reply(500, {'message': 'Server error'}),
      );

      expect(
        () => repository.getScheduleById('abc-123'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}