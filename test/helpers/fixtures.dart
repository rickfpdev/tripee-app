import 'package:intl/date_symbol_data_local.dart';

Future<void> initTestLocale() => initializeDateFormatting('pt_BR', null);


const Map<String, dynamic> scheduleListFixture = {
  'data': [
    {
      'id': 'abc-123',
      'schedule_at': '2026-05-08T09:00:00.000Z',
      'status': 'confirmed',
      'start_address': 'Av. Paulista, 1500 - Bela Vista, São Paulo - SP',
      'end_address': 'R. Bela Cintra, 900 - Consolação, São Paulo - SP',
    },
    {
      'id': 'abc-456',
      'schedule_at': '2026-05-07T16:30:00.000Z',
      'status': 'cancelled',
      'start_address': 'Rua Oliveira Pimenta, 332',
      'end_address': 'Shopping JK Iguatemi',
    },
  ],
  'page': 1,
  'limit': 15,
  'total': 45,
  'total_pages': 3,
};

const Map<String, dynamic> scheduleDetailFixture = {
  'schedule_at': '2026-05-08T09:00:00.000Z',
  'start_date': '2026-05-08T09:00:00.000Z',
  'end_date': '2026-05-08T09:45:00.000Z',
  'status': 'confirmed',
  'start': {
    'address': 'Av. Paulista, 1500 - Bela Vista, São Paulo - SP, ',
    'neighborhood': 'Bela Vista',
    'city': 'São Paulo',
    'state': 'SP',
    'country': 'Brasil',
    'zipcode': '01310-100',
    'coordinates': {
      'lat': -23.5620131893989,
      'lng': -46.65532161583988,
    },
  },
  'end': {
    'address': 'R. Bela Cintra, 900 - Consolação, São Paulo - SP, ',
    'neighborhood': 'Consolação',
    'city': 'São Paulo',
    'state': 'SP',
    'country': 'Brasil',
    'zipcode': '01415-002',
    'coordinates': {
      'lat': -23.55501942325723,
      'lng': -46.66062927398019,
    },
  },
  'route': {
    'polyline':
        't~xnCzkw{GgBzBcBpB}DpEi@l@kCoCmAqAcAcAc@[WQ_A?]DYJGHcB|CUb@wCjDjIbJhDpDn@t@`CfCf@h@_@f@g@l@[^kBvBmBzBc@g@qAuAcCkC_ImJe@i@',
    'bounds': {
      'northeast': {'lat': -23.5552392, 'lng': -46.6554955},
      'southwest': {'lat': -23.562194, 'lng': -46.6638755},
    },
    'distance': 2225,
    'duration': 685,
  },
  'estimate_route': {
    'polyline': 't~xnCzkw{GgBzBcBpB}DpEyKlMqA|AyAfBQLGBk@l@',
    'distance': 2940,
    'duration': 815,
  },
  'driver': {
    'name': 'Carlos Silva',
    'car': 'Toyota Corolla',
    'plate': 'ABC1D23',
    'photo': 'https://example.com/driver/carlos_silva.jpg',
  },
  'provider': {
    'name': 'Test',
    'category': 'Premium',
    'logo': 'https://example.com/provider/simcorp_logo.png',
  },
};