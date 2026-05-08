import 'package:flutter_test/flutter_test.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_model.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('ScheduleStatus', () {
    test('fromString mapeia todos os valores conhecidos', () {
      expect(ScheduleStatus.fromString('confirmed'), ScheduleStatus.realizada);
      expect(ScheduleStatus.fromString('completed'), ScheduleStatus.concluida);
      expect(ScheduleStatus.fromString('cancelled'), ScheduleStatus.cancelada);
      expect(ScheduleStatus.fromString('pending'), ScheduleStatus.pendente);
      expect(
          ScheduleStatus.fromString('in_progress'), ScheduleStatus.emAndamento);
      expect(ScheduleStatus.fromString(null), ScheduleStatus.unknown);
      expect(ScheduleStatus.fromString(''), ScheduleStatus.unknown);
      expect(
          ScheduleStatus.fromString('qualquer_coisa'), ScheduleStatus.unknown);
    });

    test('label retorna texto correto para cada status', () {
      expect(ScheduleStatus.realizada.label, 'Realizada');
      expect(ScheduleStatus.cancelada.label, 'Cancelada');
      expect(ScheduleStatus.pendente.label, 'Pendente');
      expect(ScheduleStatus.emAndamento.label, 'Em andamento');
    });
  });

  group('ScheduleModel.fromJson', () {
    test('parseia campos básicos corretamente', () {
      final item = scheduleListFixture['data'][0] as Map<String, dynamic>;
      final model = ScheduleModel.fromJson(item);

      expect(model.id, 'abc-123');
      expect(model.status, ScheduleStatus.realizada);
    });

    test('timeLabel formata hora corretamente', () {
      final item = scheduleListFixture['data'][0] as Map<String, dynamic>;
      final model = ScheduleModel.fromJson(item);

      // 2026-05-08T09:00:00.000Z → "09:00" (pode variar por timezone)
      expect(model.timeLabel, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    test('data inválida não lança exception', () {
      final model = ScheduleModel.fromJson({
        'id': 'x',
        'schedule_at': 'data-invalida',
        'status': 'realizada',
      });

      expect(model.id, 'x');
      // Não lança — cai no catch e usa DateTime.now()
    });

    test('id nulo resulta em string vazia', () {
      final model = ScheduleModel.fromJson({'status': 'realizada'});
      expect(model.id, '');
    });
  });

  group('PaginatedSchedulesModel.fromJson', () {
    test('parseia paginação corretamente', () {
      final paginated = PaginatedSchedulesModel.fromJson(scheduleListFixture);

      expect(paginated.currentPage, 1);
      expect(paginated.totalPages, 3);
      expect(paginated.totalItems, 45);
      expect(paginated.items.length, 2);
    });

    test('hasNextPage é true quando há mais páginas', () {
      final paginated = PaginatedSchedulesModel.fromJson(scheduleListFixture);
      expect(paginated.hasNextPage, true);
    });

    test('hasNextPage é false na última página', () {
      final lastPage = {
        ...scheduleListFixture,
        'page': 3,
        'total_pages': 3,
      };
      final paginated = PaginatedSchedulesModel.fromJson(lastPage);
      expect(paginated.hasNextPage, false);
    });

    test('lista vazia não lança exception', () {
      final empty = {
        'data': [],
        'page': 1,
        'limit': 15,
        'total': 0,
        'total_pages': 0,
      };
      final paginated = PaginatedSchedulesModel.fromJson(empty);
      expect(paginated.items, isEmpty);
      expect(paginated.hasNextPage, false);
    });

    test('parseia os dois itens do fixture corretamente', () {
      final paginated = PaginatedSchedulesModel.fromJson(scheduleListFixture);

      expect(paginated.items[0].id, 'abc-123');
      expect(paginated.items[0].status, ScheduleStatus.realizada);

      expect(paginated.items[1].id, 'abc-456');
      expect(paginated.items[1].status, ScheduleStatus.cancelada);
    });
  });
}
