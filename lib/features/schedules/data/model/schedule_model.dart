import 'package:intl/intl.dart';

enum ScheduleStatus {
  realizada,
  cancelada,
  pendente,
  emAndamento,
  concluida,
  unknown;

  static ScheduleStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'confirmed':
        return ScheduleStatus.realizada;
      case 'cancelled':
        return ScheduleStatus.cancelada;
      case 'pending':
        return ScheduleStatus.pendente;
      case 'in_progress':
        return ScheduleStatus.emAndamento;
      case 'completed':
        return ScheduleStatus.concluida;
      default:
        return ScheduleStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case ScheduleStatus.realizada:
        return 'Realizada';
      case ScheduleStatus.cancelada:
        return 'Cancelada';
      case ScheduleStatus.pendente:
        return 'Pendente';
      case ScheduleStatus.emAndamento:
        return 'Em andamento';
      case ScheduleStatus.concluida:
        return 'Concluída';
      case ScheduleStatus.unknown:
        return 'Desconhecido';
    }
  }
}

class ScheduleModel {
  final String id;
  final DateTime scheduleAt;
  final String startAddress;
  final String endAddress;
  final ScheduleStatus status;

  const ScheduleModel({
    required this.id,
    required this.scheduleAt,
    required this.startAddress,
    required this.endAddress,
    required this.status,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id']?.toString() ?? '',
      scheduleAt: _parseDate(json['schedule_at'] ?? ''),
      startAddress: _parseAddress(json['start_address'] ?? ''),
      endAddress: _parseAddress(json['end_address'] ?? ''),
      status: ScheduleStatus.fromString(json['status']?.toString()),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static String _parseAddress(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      final street = value['street'] ?? value['address'] ?? value['name'] ?? '';
      final number = value['number'] ?? '';
      if (number.toString().isNotEmpty) return '$street, $number';
      return street.toString();
    }
    return value.toString();
  }

  String get timeLabel => DateFormat('HH:mm').format(scheduleAt);
}

class PaginatedSchedulesModel {
  final List<ScheduleModel> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  const PaginatedSchedulesModel({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });

  bool get hasNextPage => currentPage < totalPages;

  factory PaginatedSchedulesModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['data'] as List?) ?? [];

    final currentPage = _parseInt(json['page'] ?? 1);
    final totalPages = _parseInt(json['total_pages'] ?? 1);
    final totalItems = _parseInt(json['total'] ?? rawItems.length);

    return PaginatedSchedulesModel(
      items: rawItems
          .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
