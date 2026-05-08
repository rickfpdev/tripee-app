import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_detail_model.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_model.dart';
import 'package:tripee_app/features/schedules/presentation/screens/schedule_detail_screen.dart';

import '../../helpers/fixtures.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });
  group('LocationPoint.fromJson', () {
    test('parseia todos os campos do contrato real', () {
      final json = scheduleDetailFixture['start'] as Map<String, dynamic>;
      final point = LocationPoint.fromJson(json);

      expect(
          point.address, 'Av. Paulista, 1500 - Bela Vista, São Paulo - SP, ');
      expect(point.neighborhood, 'Bela Vista');
      expect(point.city, 'São Paulo');
      expect(point.state, 'SP');
      expect(point.country, 'Brasil');
      expect(point.zipcode, '01310-100');
      expect(point.latitude, closeTo(-23.562, 0.001));
      expect(point.longitude, closeTo(-46.655, 0.001));
    });

    test('fullAddress monta o endereço sem campos vazios', () {
      final json = scheduleDetailFixture['start'] as Map<String, dynamic>;
      final point = LocationPoint.fromJson(json);

      expect(point.fullAddress, contains('São Paulo'));
      expect(point.fullAddress, contains('Bela Vista'));
      expect(point.fullAddress, contains('SP'));
    });

    test('json vazio não lança exception', () {
      final point = LocationPoint.fromJson({});
      expect(point.address, '');
      expect(point.latitude, isNull);
      expect(point.longitude, isNull);
    });
  });

  group('DriverModel.fromJson', () {
    test('parseia campos do contrato real', () {
      final json = scheduleDetailFixture['driver'] as Map<String, dynamic>;
      final driver = DriverModel.fromJson(json);

      expect(driver.name, 'Carlos Silva');
      expect(driver.car, 'Toyota Corolla');
      expect(driver.plate, 'ABC1D23');
      expect(driver.photoUrl, 'https://example.com/driver/carlos_silva.jpg');
    });

    test('vehicleInfo combina car e plate com separador', () {
      final json = scheduleDetailFixture['driver'] as Map<String, dynamic>;
      final driver = DriverModel.fromJson(json);

      expect(driver.vehicleInfo, 'Toyota Corolla · ABC1D23');
    });

    test('vehicleInfo com campos nulos não gera separadores extras', () {
      final driver = DriverModel.fromJson({'name': 'João'});
      expect(driver.vehicleInfo, '');
    });
  });

  group('ProviderModel.fromJson', () {
    test('parseia campos do contrato real', () {
      final json = scheduleDetailFixture['provider'] as Map<String, dynamic>;
      final provider = ProviderModel.fromJson(json);

      expect(provider.name, 'Test');
      expect(provider.category, 'Premium');
      expect(provider.logoUrl, 'https://example.com/provider/simcorp_logo.png');
    });
  });

  group('RouteModel.fromJson', () {
    test('parseia polyline, bounds, distance e duration', () {
      final json = scheduleDetailFixture['route'] as Map<String, dynamic>;
      final route = RouteModel.fromJson(json);

      expect(route.polyline, isNotNull);
      expect(route.polyline, isNotEmpty);
      expect(route.distanceMeters, 2225);
      expect(route.durationSeconds, 685);
      expect(route.bounds, isNotNull);
      expect(route.bounds!.northeast.lat, closeTo(-23.555, 0.001));
      expect(route.bounds!.southwest.lng, closeTo(-46.663, 0.001));
    });

    test('formattedDistance converte metros para km quando >= 1000', () {
      final route = RouteModel.fromJson({
        'polyline': '',
        'distance': 2225,
        'duration': 685,
      });
      expect(route.formattedDistance, '2.2 km');
    });

    test('formattedDistance mantém metros quando < 1000', () {
      final route = RouteModel.fromJson({
        'polyline': '',
        'distance': 850,
        'duration': 120,
      });
      expect(route.formattedDistance, '850 m');
    });

    test('formattedDuration arredonda para cima em minutos', () {
      final route = RouteModel.fromJson({
        'polyline': '',
        'distance': 2225,
        'duration': 685, // 685 / 60 = 11.4 → ceil = 12
      });
      expect(route.formattedDuration, '12 min');
    });
  });

  group('EstimatedRouteModel.fromJson', () {
    test('parseia campos do contrato real (estimate_route sem bounds)', () {
      final json =
          scheduleDetailFixture['estimate_route'] as Map<String, dynamic>;
      final route = EstimatedRouteModel.fromJson(json);

      expect(route.polyline, isNotNull);
      expect(route.distanceMeters, 2940);
      expect(route.durationSeconds, 815);
    });

    test('formattedDistance e formattedDuration funcionam', () {
      final json =
          scheduleDetailFixture['estimate_route'] as Map<String, dynamic>;
      final route = EstimatedRouteModel.fromJson(json);

      expect(route.formattedDistance, '2.9 km');
      expect(route.formattedDuration, '14 min'); // 815 / 60 = 13.58 → 14
    });
  });

  group('ScheduleDetailModel.fromJson', () {
    test('parseia o fixture completo sem erros', () {
      final model = ScheduleDetailModel.fromJson(scheduleDetailFixture);

      expect(model.status, ScheduleStatus.realizada);
      expect(model.scheduledAt, isNotNull);
      expect(model.startDate, isNotNull);
      expect(model.endDate, isNotNull);
      expect(model.origin.city, 'São Paulo');
      expect(model.destination.neighborhood, 'Consolação');
      expect(model.driver, isNotNull);
      expect(model.driver!.name, 'Carlos Silva');
      expect(model.provider, isNotNull);
      expect(model.provider!.category, 'Premium');
      expect(model.route, isNotNull);
      expect(model.estimatedRoute, isNotNull);
      expect(model.rating, isNull); // não existe no contrato
    });

    test('aceita wrapper data se presente', () {
      final wrapped = {'data': scheduleDetailFixture};
      final model = ScheduleDetailModel.fromJson(wrapped);

      expect(model.status, ScheduleStatus.realizada);
      expect(model.origin.city, 'São Paulo');
    });

    test('formattedStartDate retorna string não vazia', () {
      final model = ScheduleDetailModel.fromJson(scheduleDetailFixture);
      expect(model.formattedStartDate, isNotEmpty);
    });

    test('formattedEndDate retorna string não vazia', () {
      final model = ScheduleDetailModel.fromJson(scheduleDetailFixture);
      expect(model.formattedEndDate, isNotEmpty);
    });

    test('campos opcionais ausentes não lançam exception', () {
      final minimal = {
        'status': 'confirmed',
        'start': {'address': 'Origem'},
        'end': {'address': 'Destino'},
      };
      final model = ScheduleDetailModel.fromJson(minimal);

      expect(model.driver, isNull);
      expect(model.provider, isNull);
      expect(model.route, isNull);
      expect(model.estimatedRoute, isNull);
    });
  });

  group('decodePolyline', () {
    test('decodifica a polyline do route e retorna pontos', () {
      final polyline = (scheduleDetailFixture['route']
          as Map<String, dynamic>)['polyline'] as String;
      final points = decodePolyline(polyline);

      expect(points, isNotEmpty);
      // Todos os pontos devem ser coordenadas válidas de São Paulo
      for (final p in points) {
        expect(p.length, 2);
        expect(p[0], closeTo(-23.5, 0.5)); // lat
        expect(p[1], closeTo(-46.6, 0.5)); // lng
      }
    });

    test('decodifica a polyline do estimate_route e retorna pontos', () {
      final polyline = (scheduleDetailFixture['estimate_route']
          as Map<String, dynamic>)['polyline'] as String;
      final points = decodePolyline(polyline);

      expect(points, isNotEmpty);
      expect(points.length, greaterThan(3));
    });

    test('polyline vazia retorna lista vazia', () {
      final points = decodePolyline('');
      expect(points, isEmpty);
    });
  });
}
