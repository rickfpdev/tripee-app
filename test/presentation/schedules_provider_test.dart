import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tripee_app/core/errors/exceptions.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_model.dart';
import 'package:tripee_app/features/schedules/presentation/providers/schedules_provider.dart';

import '../helpers/mock_repository.dart';
import '../helpers/fixtures.dart';

void main() {
  late MockSchedulesRepository mockRepo;
  late SchedulesProvider provider;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  // Páginas mockadas para testes de paginação
  final page1 = PaginatedSchedulesModel.fromJson(scheduleListFixture);
  final page2 = PaginatedSchedulesModel.fromJson({
    ...scheduleListFixture,
    'data': [
      {
        'id': 'abc-789',
        'schedule_at': '2026-05-06T10:00:00.000Z',
        'status': 'cancelada',
        'start_address': 'Rua X',
        'end_address': 'Rua Y',
      }
    ],
    'page': 2,
    'total_pages': 3,
  });
  final page3 = PaginatedSchedulesModel.fromJson({
    ...scheduleListFixture,
    'data': [
      {
        'id': 'abc-999',
        'schedule_at': '2026-05-05T08:00:00.000Z',
        'status': 'realizada',
        'start_address': 'Rua A',
        'end_address': 'Rua B',
      }
    ],
    'page': 3,
    'total_pages': 3,
  });

  setUp(() {
    mockRepo = MockSchedulesRepository();
    provider = SchedulesProvider(repository: mockRepo);
  });

  tearDown(() {
    provider.dispose();
  });

  group('estado inicial', () {
    test('começa como idle com lista vazia', () {
      expect(provider.state, LoadingState.idle);
      expect(provider.items, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.hasMore, false);
    });
  });

  group('loadInitial', () {
    test('vai para loading e depois loaded ao ter sucesso', () async {
      when(() => mockRepo.getSchedules(page: 1))
          .thenAnswer((_) async => page1);

      final states = <LoadingState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadInitial();

      expect(states, containsAllInOrder([
        LoadingState.loading,
        LoadingState.loaded,
      ]));
      expect(provider.items.length, 2);
    });

    test('popula itens corretamente', () async {
      when(() => mockRepo.getSchedules(page: 1))
          .thenAnswer((_) async => page1);

      await provider.loadInitial();

      expect(provider.items[0].id, 'abc-123');
      expect(provider.items[1].id, 'abc-456');
    });

    test('vai para error quando o repositório lança exceção', () async {
      when(() => mockRepo.getSchedules(page: 1))
          .thenThrow(const NetworkException());

      await provider.loadInitial();

      expect(provider.state, LoadingState.error);
      expect(provider.errorMessage, isNotNull);
      expect(provider.items, isEmpty);
    });

    test('reinicia lista ao chamar loadInitial novamente', () async {
      when(() => mockRepo.getSchedules(page: 1))
          .thenAnswer((_) async => page1);

      await provider.loadInitial();
      expect(provider.items.length, 2);

      await provider.loadInitial();
      // Não deve duplicar — reinicia do zero
      expect(provider.items.length, 2);
    });
  });

  group('loadMore', () {
    test('acumula itens das páginas seguintes', () async {
      when(() => mockRepo.getSchedules(page: 1))
          .thenAnswer((_) async => page1);
      when(() => mockRepo.getSchedules(page: 2))
          .thenAnswer((_) async => page2);

      await provider.loadInitial();
      await provider.loadMore();

      expect(provider.items.length, 3); // 2 da page1 + 1 da page2
    });

    test('hasMore é false na última página', () async {
      when(() => mockRepo.getSchedules(page: 1))
          .thenAnswer((_) async => page1);
      when(() => mockRepo.getSchedules(page: 2))
          .thenAnswer((_) async => page2);
      when(() => mockRepo.getSchedules(page: 3))
          .thenAnswer((_) async => page3);

      await provider.loadInitial();
      await provider.loadMore();
      await provider.loadMore();

      expect(provider.hasMore, false);
    });

    test('não chama repo se não há mais páginas', () async {
      when(() => mockRepo.getSchedules(page: 1))
          .thenAnswer((_) async => page1);
      when(() => mockRepo.getSchedules(page: 2))
          .thenAnswer((_) async => page2);
      when(() => mockRepo.getSchedules(page: 3))
          .thenAnswer((_) async => page3);

      await provider.loadInitial();
      await provider.loadMore();
      await provider.loadMore();

      // Tentar loadMore na última página não deve chamar o repo
      await provider.loadMore();

      verify(() => mockRepo.getSchedules(page: any(named: 'page')))
          .called(3); // page 1, 2 e 3 — nunca page 4
    });

    test('vai para estado de erro mas mantém itens já carregados', () async {
      when(() => mockRepo.getSchedules(page: 1))
          .thenAnswer((_) async => page1);
      when(() => mockRepo.getSchedules(page: 2))
          .thenThrow(const NetworkException());

      await provider.loadInitial();
      await provider.loadMore();

      expect(provider.state, LoadingState.error);
      expect(provider.items.length, 2); // itens da página 1 preservados
    });
  });

  group('filtro de datas', () {
    test('applyDateFilter reinicia para página 1', () async {
      when(() => mockRepo.getSchedules(
            page: 1,
            dateFrom: any(named: 'dateFrom'),
            dateTo: any(named: 'dateTo'),
          )).thenAnswer((_) async => page1);

      await provider.applyDateFilter(
        dateFrom: DateTime(2026, 5, 1),
        dateTo: DateTime(2026, 5, 8),
      );

      expect(provider.hasAppliedFilter, true);
      expect(provider.dateFrom, DateTime(2026, 5, 1));
      expect(provider.dateTo, DateTime(2026, 5, 8));
    });

    test('clearFilter remove datas e recarrega', () async {
      when(() => mockRepo.getSchedules(page: 1))
          .thenAnswer((_) async => page1);
      when(() => mockRepo.getSchedules(
            page: 1,
            dateFrom: any(named: 'dateFrom'),
            dateTo: any(named: 'dateTo'),
          )).thenAnswer((_) async => page1);

      await provider.applyDateFilter(
        dateFrom: DateTime(2026, 5, 1),
        dateTo: DateTime(2026, 5, 8),
      );
      await provider.clearFilter();

      expect(provider.hasAppliedFilter, false);
      expect(provider.dateFrom, isNull);
      expect(provider.dateTo, isNull);
    });

    test('filterLabel retorna "Período" sem filtro ativo', () {
      expect(provider.filterLabel, 'Período');
    });

    test('filterLabel formata datas quando filtro ativo', () async {
      when(() => mockRepo.getSchedules(
            page: 1,
            dateFrom: any(named: 'dateFrom'),
            dateTo: any(named: 'dateTo'),
          )).thenAnswer((_) async => page1);

      await provider.applyDateFilter(
        dateFrom: DateTime(2026, 5, 1),
        dateTo: DateTime(2026, 5, 8),
      );

      expect(provider.filterLabel, isNot('Período'));
      expect(provider.filterLabel, contains('/'));
    });
  });

  group('groupedItems', () {
    test('retorna lista vazia quando não há itens', () {
      expect(provider.groupedItems, isEmpty);
    });

    test('agrupa itens por data corretamente', () async {
      when(() => mockRepo.getSchedules(page: 1))
          .thenAnswer((_) async => page1);

      await provider.loadInitial();

      final groups = provider.groupedItems;
      expect(groups, isNotEmpty);
      // Cada grupo tem pelo menos um item
      for (final group in groups) {
        expect(group.items, isNotEmpty);
      }
    });
  });
}