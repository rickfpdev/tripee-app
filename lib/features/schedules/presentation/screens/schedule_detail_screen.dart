import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripee_app/core/theme/app_theme.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_detail_model.dart';
import 'package:tripee_app/features/schedules/presentation/providers/schedules_detail_provider.dart';
import 'package:tripee_app/features/schedules/presentation/widgets/status_badget.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final String scheduleId;

  const ScheduleDetailScreen({super.key, required this.scheduleId});

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleDetailProvider>().loadDetail(widget.scheduleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Detalhes da corrida'),
      ),
      body: Consumer<ScheduleDetailProvider>(
        builder: (context, provider, _) {
          switch (provider.state) {
            case DetailLoadingState.idle:
            case DetailLoadingState.loading:
              return const _LoadingView();

            case DetailLoadingState.error:
              return _ErrorView(
                message: provider.errorMessage ?? 'Erro ao carregar detalhes.',
                onRetry: () => provider.retry(widget.scheduleId),
              );

            case DetailLoadingState.loaded:
              return _DetailBody(detail: provider.detail!);
          }
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ScheduleDetailModel detail;

  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MapPlaceholder(detail: detail),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(status: detail.status, filled: true),
                const SizedBox(height: 20),
                _RouteSection(detail: detail),
                const SizedBox(height: 24),
                if (detail.driver != null) ...[
                  _DriverSection(driver: detail.driver!),
                  const SizedBox(height: 24),
                ],
                if (detail.provider != null) ...[
                  _ProviderSection(provider: detail.provider!),
                  const SizedBox(height: 24),
                ],
                if (detail.route != null || detail.estimatedRoute != null) ...[
                  _RouteInfoSection(
                    route: detail.route,
                    estimatedRoute: detail.estimatedRoute,
                  ),
                  const SizedBox(height: 24),
                ],
                if (detail.rating != null) ...[
                  _RatingSection(rating: detail.rating!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<List<double>> decodePolyline(String encoded) {
  final result = <List<double>>[];
  int index = 0;
  int lat = 0;
  int lng = 0;

  while (index < encoded.length) {
    int shift = 0;
    int b;
    int result0 = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result0 |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dLat = (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
    lat += dLat;

    shift = 0;
    result0 = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result0 |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dLng = (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
    lng += dLng;

    result.add([lat / 1e5, lng / 1e5]);
  }

  return result;
}

class _MapPlaceholder extends StatelessWidget {
  final ScheduleDetailModel detail;

  const _MapPlaceholder({required this.detail});

  @override
  Widget build(BuildContext context) {
    final realizedPoints = detail.route?.polyline != null
        ? decodePolyline(detail.route!.polyline!)
        : <List<double>>[];
    final estimatedPoints = detail.estimatedRoute?.polyline != null
        ? decodePolyline(detail.estimatedRoute!.polyline!)
        : <List<double>>[];

    final allPoints = [...realizedPoints, ...estimatedPoints];

    return ClipRect(
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 220),
              painter: _RoutePainter(
                realizedPoints: realizedPoints,
                estimatedPoints: estimatedPoints,
                allPoints: allPoints,
              ),
            ),
            if (realizedPoints.isNotEmpty)
              _FloatingPin(
                points: allPoints,
                latLng: realizedPoints.first,
                label: _truncate(detail.origin.address),
                isOrigin: true,
                canvasSize: Size(MediaQuery.of(context).size.width, 220),
              ),
            if (realizedPoints.isNotEmpty)
              _FloatingPin(
                points: allPoints,
                latLng: realizedPoints.last,
                label: _truncate(detail.destination.address),
                isOrigin: false,
                canvasSize: Size(MediaQuery.of(context).size.width, 220),
              ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 16, height: 3, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text('Realizado', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 10),
                    Container(width: 16, height: 3, color: Colors.orange),
                    const SizedBox(width: 4),
                    const Text('Estimado', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncate(String s) {
    if (s.length <= 22) return s;
    return '${s.substring(0, 20)}...';
  }
}

class _Projector {
  final double minLat, maxLat, minLng, maxLng;
  final Size canvasSize;
  final double padding;

  _Projector({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.canvasSize,
    // ignore: unused_element
    this.padding = 32,
  });

  factory _Projector.fromPoints(List<List<double>> points, Size canvasSize) {
    double minLat = points.first[0];
    double maxLat = points.first[0];
    double minLng = points.first[1];
    double maxLng = points.first[1];

    for (final p in points) {
      if (p[0] < minLat) minLat = p[0];
      if (p[0] > maxLat) maxLat = p[0];
      if (p[1] < minLng) minLng = p[1];
      if (p[1] > maxLng) maxLng = p[1];
    }

    return _Projector(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
      canvasSize: canvasSize,
    );
  }

  Offset project(double lat, double lng) {
    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;

    final effectiveLat = latRange == 0 ? 1 : latRange;
    final effectiveLng = lngRange == 0 ? 1 : lngRange;

    final drawW = canvasSize.width - padding * 2;
    final drawH = canvasSize.height - padding * 2;

    final scaleX = drawW / effectiveLng;
    final scaleY = drawH / effectiveLat;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final offsetX = (canvasSize.width - effectiveLng * scale) / 2;
    final offsetY = (canvasSize.height - effectiveLat * scale) / 2;

    final x = offsetX + (lng - minLng) * scale;
    final y = offsetY + (maxLat - lat) * scale;

    return Offset(x, y);
  }
}

class _RoutePainter extends CustomPainter {
  final List<List<double>> realizedPoints;
  final List<List<double>> estimatedPoints;
  final List<List<double>> allPoints;

  _RoutePainter({
    required this.realizedPoints,
    required this.estimatedPoints,
    required this.allPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFFEAEFED);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (allPoints.isEmpty) return;

    final projector = _Projector.fromPoints(allPoints, size);

    _drawMapBackground(canvas, size, projector);

    if (estimatedPoints.isNotEmpty) {
      _drawPolyline(canvas, estimatedPoints, projector,
          color: Colors.orange, strokeWidth: 4, dashed: true);
    }

    if (realizedPoints.isNotEmpty) {
      _drawPolyline(canvas, realizedPoints, projector,
          color: AppColors.primary, strokeWidth: 4, dashed: false);
    }
  }

  void _drawMapBackground(Canvas canvas, Size size, _Projector projector) {
    final roadPaint = Paint()..color = const Color(0xFFFFFFFF);
    final blockPaint = Paint()..color = const Color(0xFFDDE5D0);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFE8EDE5));

    const blockSize = 36.0;
    const roadWidth = 8.0;
    const step = blockSize + roadWidth;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, blockSize, blockSize),
          blockPaint,
        );
      }
    }

    for (double y = blockSize; y < size.height; y += step) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, roadWidth),
        roadPaint,
      );
    }

    for (double x = blockSize; x < size.width; x += step) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, roadWidth, size.height),
        roadPaint,
      );
    }
  }

  void _drawPolyline(
    Canvas canvas,
    List<List<double>> points,
    _Projector projector, {
    required Color color,
    required double strokeWidth,
    required bool dashed,
  }) {
    final projected = points.map((p) => projector.project(p[0], p[1])).toList();

    final casingPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = strokeWidth + 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (dashed) {
      _drawDashedPath(canvas, projected, casingPaint, dashLen: 14, gapLen: 8);
      _drawDashedPath(canvas, projected, routePaint, dashLen: 14, gapLen: 8);
    } else {
      final path = _buildPath(projected);
      canvas.drawPath(path, casingPaint);
      canvas.drawPath(path, routePaint);
    }
  }

  Path _buildPath(List<Offset> points) {
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }

  void _drawDashedPath(
    Canvas canvas,
    List<Offset> points,
    Paint paint, {
    required double dashLen,
    required double gapLen,
  }) {
    double remaining = 0;
    bool drawing = true;

    for (int i = 1; i < points.length; i++) {
      final start = points[i - 1];
      final end = points[i];
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final segLen = (Offset(dx, dy)).distance;
      double traveled = 0;

      while (traveled < segLen) {
        final segRemaining = segLen - traveled;
        final step = drawing
            ? (dashLen - remaining).clamp(0, segRemaining)
            : (gapLen - remaining).clamp(0, segRemaining);

        if (drawing) {
          final x0 = start.dx + dx * traveled / segLen;
          final y0 = start.dy + dy * traveled / segLen;
          final x1 = start.dx + dx * (traveled + step) / segLen;
          final y1 = start.dy + dy * (traveled + step) / segLen;
          canvas.drawLine(Offset(x0, y0), Offset(x1, y1), paint);
        }

        remaining += step;
        traveled += step;

        final limit = drawing ? dashLen : gapLen;
        if (remaining >= limit) {
          remaining = 0;
          drawing = !drawing;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.realizedPoints != realizedPoints ||
      old.estimatedPoints != estimatedPoints;
}

class _FloatingPin extends StatelessWidget {
  final List<List<double>> points;
  final List<double> latLng;
  final String label;
  final bool isOrigin;
  final Size canvasSize;

  const _FloatingPin({
    required this.points,
    required this.latLng,
    required this.label,
    required this.isOrigin,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final projector = _Projector.fromPoints(points, canvasSize);
    final offset = projector.project(latLng[0], latLng[1]);

    return Positioned(
      left: (offset.dx - 8).clamp(4, canvasSize.width - 120),
      top: (offset.dy - 24).clamp(4, canvasSize.height - 36),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOrigin ? Icons.radio_button_checked : Icons.location_on,
              size: 12,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteSection extends StatelessWidget {
  final ScheduleDetailModel detail;

  const _RouteSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LocationTile(
          label: 'Origem',
          dateTimeLabel: detail.formattedStartDate,
          address: detail.origin.fullAddress,
          isOrigin: true,
        ),
        const SizedBox(height: 12),
        _LocationTile(
          label: 'Destino',
          dateTimeLabel: detail.formattedEndDate,
          address: detail.destination.fullAddress,
          isOrigin: false,
        ),
      ],
    );
  }
}

class _LocationTile extends StatelessWidget {
  final String label;
  final String dateTimeLabel;
  final String address;
  final bool isOrigin;

  const _LocationTile({
    required this.label,
    required this.dateTimeLabel,
    required this.address,
    required this.isOrigin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isOrigin ? Icons.radio_button_checked : Icons.location_on,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    if (dateTimeLabel.isNotEmpty)
                      TextSpan(
                        text: ' · $dateTimeLabel',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(address, style: AppTextStyles.address),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverSection extends StatelessWidget {
  final DriverModel driver;

  const _DriverSection({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.divider,
          child: Icon(Icons.person, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(driver.name, style: AppTextStyles.detailTitle),
              if (driver.vehicleInfo.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(driver.vehicleInfo, style: AppTextStyles.address),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderSection extends StatelessWidget {
  final ProviderModel provider;

  const _ProviderSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Politicas de Solicitação',
      children: [
        if (provider.category != null)
          _DetailRow(label: 'Categoria', value: provider.category!),
        _DetailRow(label: 'Fornecedor', value: provider.name),
      ],
    );
  }
}

class _RouteInfoSection extends StatelessWidget {
  final RouteModel? route;
  final EstimatedRouteModel? estimatedRoute;

  const _RouteInfoSection({this.route, this.estimatedRoute});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informações da rota', style: AppTextStyles.detailTitle),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              children: [
                const SizedBox.shrink(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Realizado',
                    style: AppTextStyles.detailLabel
                        .copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Estimado',
                    style: AppTextStyles.detailLabel
                        .copyWith(color: Colors.orange),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            TableRow(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('Distância', style: AppTextStyles.detailLabel),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    route?.formattedDistance ?? '—',
                    style: AppTextStyles.detailValue,
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    estimatedRoute?.formattedDistance ?? '—',
                    style: AppTextStyles.detailValue,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            TableRow(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('Duração', style: AppTextStyles.detailLabel),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    route?.formattedDuration ?? '—',
                    style: AppTextStyles.detailValue,
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    estimatedRoute?.formattedDuration ?? '—',
                    style: AppTextStyles.detailValue,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _RatingSection extends StatelessWidget {
  final RatingModel rating;

  const _RatingSection({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Avaliação', style: AppTextStyles.detailTitle),
        const SizedBox(height: 10),
        _StarRating(score: rating.score),
        if (rating.comment != null && rating.comment!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '"${rating.comment}"',
            style: AppTextStyles.address.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}

class _StarRating extends StatelessWidget {
  final double score;

  const _StarRating({required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < score.floor();
        final half = !filled && i < score;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          color: const Color(0xFFFFC107),
          size: 28,
        );
      }),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.detailTitle),
        const SizedBox(height: 8),
        ...children.expand((w) => [w, const Divider(height: 1)]).toList()
          ..removeLast(),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AppTextStyles.detailLabel),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.detailValue),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
