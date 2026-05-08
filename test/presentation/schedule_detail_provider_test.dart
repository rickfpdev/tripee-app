import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tripee_app/core/errors/exceptions.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_detail_model.dart';
import 'package:tripee_app/features/schedules/presentation/providers/schedules_detail_provider.dart';

import '../helpers/mock_repository.dart';
import '../helpers/fixtures.dart';

void main() {
  late MockSchedulesRepository mockRepo;
  late ScheduleDetailProvider provider;

  final detailModel = ScheduleDetailModel.fromJson(scheduleDetailFixture);

  setUp(() {
    mockRepo = MockSchedulesRepository();
    provider = ScheduleDetailProvider(repository: mockRepo);
  });

  tearDown(() {
    provider.dispose();
  });

  group('estado inicial', () {
    test('começa como idle sem detalhe carregado', () {
      expect(provider.state, DetailLoadingState.idle);
      expect(provider.detail, isNull);
      expect(provider.errorMessage, isNull);
    });
  });

  group('loadDetail', () {
    test('vai para loading e depois loaded ao ter sucesso', () async {
      when(() => mockRepo.getScheduleById('abc-123'))
          .thenAnswer((_) async => detailModel);

      final states = <DetailLoadingState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadDetail('abc-123');

      expect(
          states,
          containsAllInOrder([
            DetailLoadingState.loading,
            DetailLoadingState.loaded,
          ]));
    });

    test('popula detail corretamente', () async {
      when(() => mockRepo.getScheduleById('abc-123'))
          .thenAnswer((_) async => detailModel);

      await provider.loadDetail('abc-123');

      expect(provider.detail, isNotNull);
      expect(provider.detail!.origin.city, 'São Paulo');
      expect(provider.detail!.driver!.name, 'Carlos Silva');
    });

    test('vai para error e salva mensagem ao falhar', () async {
      when(() => mockRepo.getScheduleById('abc-123'))
          .thenThrow(const NotFoundException());

      await provider.loadDetail('abc-123');

      expect(provider.state, DetailLoadingState.error);
      expect(provider.errorMessage, isNotNull);
      expect(provider.detail, isNull);
    });

    test('limpa detail anterior ao iniciar novo carregamento', () async {
      when(() => mockRepo.getScheduleById('abc-123'))
          .thenAnswer((_) async => detailModel);

      await provider.loadDetail('abc-123');
      expect(provider.detail, isNotNull);

      // Simula carregamento de outro id com erro
      when(() => mockRepo.getScheduleById('outro-id'))
          .thenThrow(const NetworkException());

      await provider.loadDetail('outro-id');

      // detail deve ter sido limpo antes do erro
      expect(provider.detail, isNull);
    });
  });

  group('retry', () {
    test('chama loadDetail novamente com o mesmo id', () async {
      when(() => mockRepo.getScheduleById('abc-123'))
          .thenAnswer((_) async => detailModel);

      await provider.retry('abc-123');

      verify(() => mockRepo.getScheduleById('abc-123')).called(1);
      expect(provider.state, DetailLoadingState.loaded);
    });
  });
}
