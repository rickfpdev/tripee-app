import 'package:intl/intl.dart';
import 'schedule_model.dart';

class LocationPoint {
  final String address;
  final String neighborhood;
  final String city;
  final String state;
  final String country;
  final String zipcode;
  final double? latitude;
  final double? longitude;

  const LocationPoint({
    required this.address,
    this.neighborhood = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.zipcode = '',
    this.latitude,
    this.longitude,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>?;
    return LocationPoint(
      address: json['address']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      zipcode: json['zipcode']?.toString() ?? '',
      latitude: (coords?['lat'] as num?)?.toDouble(),
      longitude: (coords?['lng'] as num?)?.toDouble(),
    );
  }

  String get fullAddress {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address.trimRight().replaceAll(RegExp(r',\s*$'), ''));
    if (neighborhood.isNotEmpty) parts.add(neighborhood);
    if (city.isNotEmpty && state.isNotEmpty) {
      parts.add('$city - $state');
    } else if (city.isNotEmpty) {
      parts.add(city);
    }
    return parts.join(', ');
  }
}

class DriverModel {
  final String name;
  final String? car;
  final String? plate;
  final String? photoUrl;

  const DriverModel({
    required this.name,
    this.car,
    this.plate,
    this.photoUrl,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      name: json['name']?.toString() ?? '',
      car: json['car']?.toString(),
      plate: json['plate']?.toString(),
      photoUrl: json['photo']?.toString(),
    );
  }

  String get vehicleInfo {
    final parts = <String>[];
    if (car != null) parts.add(car!);
    if (plate != null) parts.add(plate!);
    return parts.join(' · ');
  }
}

class ProviderModel {
  final String name;
  final String? category;
  final String? logoUrl;

  const ProviderModel({
    required this.name,
    this.category,
    this.logoUrl,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      logoUrl: json['logo']?.toString(),
    );
  }
}

class LatLng {
  final double lat;
  final double lng;

  const LatLng({required this.lat, required this.lng});

  factory LatLng.fromJson(Map<String, dynamic> json) {
    return LatLng(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class RouteBounds {
  final LatLng northeast;
  final LatLng southwest;

  const RouteBounds({required this.northeast, required this.southwest});

  factory RouteBounds.fromJson(Map<String, dynamic> json) {
    return RouteBounds(
      northeast: LatLng.fromJson(json['northeast'] as Map<String, dynamic>),
      southwest: LatLng.fromJson(json['southwest'] as Map<String, dynamic>),
    );
  }
}

class RouteModel {
  final String? polyline;
  final RouteBounds? bounds;
  final int? distanceMeters;
  final int? durationSeconds;

  const RouteModel({this.polyline, this.bounds, this.distanceMeters, this.durationSeconds});

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      polyline: json['polyline']?.toString(),
      bounds: json['bounds'] != null
          ? RouteBounds.fromJson(json['bounds'] as Map<String, dynamic>)
          : null,
      distanceMeters: (json['distance'] as num?)?.toInt(),
      durationSeconds: (json['duration'] as num?)?.toInt(),
    );
  }

  String get formattedDistance {
    if (distanceMeters == null) return '';
    if (distanceMeters! >= 1000) {
      return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
    }
    return '$distanceMeters m';
  }

  String get formattedDuration {
    if (durationSeconds == null) return '';
    final minutes = (durationSeconds! / 60).ceil();
    return '$minutes min';
  }
}

class EstimatedRouteModel {
  final String? polyline;
  final int? distanceMeters;
  final int? durationSeconds;

  const EstimatedRouteModel({
    this.polyline,
    this.distanceMeters,
    this.durationSeconds,
  });

  factory EstimatedRouteModel.fromJson(Map<String, dynamic> json) {
    return EstimatedRouteModel(
      polyline: json['polyline']?.toString(),
      distanceMeters: (json['distance'] as num?)?.toInt(),
      durationSeconds: (json['duration'] as num?)?.toInt(),
    );
  }

  String get formattedDistance {
    if (distanceMeters == null) return '';
    if (distanceMeters! >= 1000) {
      return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
    }
    return '$distanceMeters m';
  }

  String get formattedDuration {
    if (durationSeconds == null) return '';
    final minutes = (durationSeconds! / 60).ceil();
    return '$minutes min';
  }
}

class RatingModel {
  final double score;
  final String? comment;

  const RatingModel({required this.score, this.comment});

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      comment: json['comment']?.toString(),
    );
  }
}

class ScheduleDetailModel {
  final DateTime? scheduledAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final ScheduleStatus status;
  final LocationPoint origin;
  final LocationPoint destination;
  final RouteModel? route;
  final EstimatedRouteModel? estimatedRoute;
  final DriverModel? driver;
  final ProviderModel? provider;
  final RatingModel? rating;

  const ScheduleDetailModel({
    this.scheduledAt,
    this.startDate,
    this.endDate,
    required this.status,
    required this.origin,
    required this.destination,
    this.route,
    this.estimatedRoute,
    this.driver,
    this.provider,
    this.rating,
  });

  factory ScheduleDetailModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return ScheduleDetailModel(
      scheduledAt: _parseDate(data['schedule_at']),
      startDate: _parseDate(data['start_date']),
      endDate: _parseDate(data['end_date']),
      status: ScheduleStatus.fromString(data['status']?.toString()),
      origin: LocationPoint.fromJson(data['start'] as Map<String, dynamic>? ?? {}),
      destination: LocationPoint.fromJson(data['end'] as Map<String, dynamic>? ?? {}),
      route: data['route'] != null
          ? RouteModel.fromJson(data['route'] as Map<String, dynamic>)
          : null,
      estimatedRoute: data['estimate_route'] != null
          ? EstimatedRouteModel.fromJson(data['estimate_route'] as Map<String, dynamic>)
          : null,
      driver: data['driver'] != null
          ? DriverModel.fromJson(data['driver'] as Map<String, dynamic>)
          : null,
      provider: data['provider'] != null
          ? ProviderModel.fromJson(data['provider'] as Map<String, dynamic>)
          : null,
      rating: data['rating'] != null
          ? RatingModel.fromJson(data['rating'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String get formattedScheduledAt {
    if (scheduledAt == null) return '';
    return DateFormat("dd 'de' MMM, yyyy '·' HH:mm", 'pt_BR').format(scheduledAt!);
  }

  String get formattedStartDate {
    if (startDate == null) return '';
    return DateFormat("dd MMM, yyyy '·' HH:mm", 'pt_BR').format(startDate!);
  }

  String get formattedEndDate {
    if (endDate == null) return '';
    return DateFormat("dd MMM, yyyy '·' HH:mm", 'pt_BR').format(endDate!);
  }
}