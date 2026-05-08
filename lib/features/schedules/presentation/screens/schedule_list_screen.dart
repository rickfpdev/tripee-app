import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripee_app/core/theme/app_theme.dart';
import 'package:tripee_app/features/schedules/data/model/schedule_model.dart';
import 'package:tripee_app/features/schedules/presentation/widgets/data_range_filter_sheet.dart';
import '../providers/schedules_provider.dart';
import '../widgets/schedule_list_item.dart';
import 'schedule_detail_screen.dart';

class SchedulesListScreen extends StatefulWidget {
  const SchedulesListScreen({super.key});

  @override
  State<SchedulesListScreen> createState() => _SchedulesListScreenState();
}

class _SchedulesListScreenState extends State<SchedulesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SchedulesProvider>().loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    const threshold = 200.0;

    if (currentScroll >= maxScroll - threshold) {
      context.read<SchedulesProvider>().loadMore();
    }
  }

  void _openDateFilter(BuildContext context) {
    final provider = context.read<SchedulesProvider>();
    showDateRangeFilter(
      context,
      initialDateFrom: provider.dateFrom,
      initialDateTo: provider.dateTo,
      onApply: (from, to) =>
          provider.applyDateFilter(dateFrom: from, dateTo: to),
      onClear: () => provider.clearFilter(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Histórico'),
      ),
      body: Column(
        children: [
          _FilterBar(onTapFilter: () => _openDateFilter(context)),
          Expanded(child: _Body(scrollController: _scrollController)),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final VoidCallback onTapFilter;

  const _FilterBar({required this.onTapFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Consumer<SchedulesProvider>(
                builder: (context, provider, _) {
                  final hasFilter = provider.hasAppliedFilter;
                  return GestureDetector(
                    onTap: onTapFilter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: hasFilter
                            ? AppColors.primary.withOpacity(0.08)
                            : AppColors.surface,
                        border: Border.all(
                          color:
                              hasFilter ? AppColors.primary : AppColors.divider,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.filterLabel,
                            style: AppTextStyles.filterChip.copyWith(
                              color: hasFilter
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight:
                                  hasFilter ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: hasFilter
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar',
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Icon(Icons.search, color: AppColors.textHint, size: 20),
                SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final ScrollController scrollController;

  const _Body({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<SchedulesProvider>(
      builder: (context, provider, _) {
        switch (provider.state) {
          case LoadingState.idle:
          case LoadingState.loading:
            return const _LoadingView();

          case LoadingState.error:
            if (provider.items.isEmpty) {
              return _ErrorView(
                message: provider.errorMessage ?? 'Erro ao carregar.',
                onRetry: provider.retry,
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      provider.errorMessage ?? 'Erro ao carregar mais itens.'),
                  action: SnackBarAction(
                    label: 'Tentar novamente',
                    onPressed: provider.loadMore,
                  ),
                ),
              );
            });
            return _ListView(
                scrollController: scrollController, provider: provider);

          case LoadingState.loaded:
          case LoadingState.loadingMore:
            if (provider.items.isEmpty) {
              return const _EmptyView();
            }
            return _ListView(
                scrollController: scrollController, provider: provider);
        }
      },
    );
  }
}

class _ListView extends StatelessWidget {
  final ScrollController scrollController;
  final SchedulesProvider provider;

  const _ListView({
    required this.scrollController,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final groups = provider.groupedItems;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _itemCount(groups, provider),
      itemBuilder: (context, index) {
        return _buildItem(context, index, groups, provider);
      },
    );
  }

  int _itemCount(List<SchedulesGrouped> groups, SchedulesProvider provider) {
    int count = groups.fold(0, (sum, g) => sum + 1 + g.items.length);
    
    if (provider.state == LoadingState.loadingMore || provider.hasMore) count++;
    return count;
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    List<SchedulesGrouped> groups,
    SchedulesProvider provider,
  ) {
    int cursor = 0;

    for (final group in groups) {
      if (index == cursor) {
        return _SectionHeader(label: group.label);
      }
      cursor++;

      for (final item in group.items) {
        if (index == cursor) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ScheduleListItem(
              schedule: item,
              onTap: () => _openDetail(context, item),
            ),
          );
        }
        cursor++;
      }
    }

    if (provider.state == LoadingState.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    
    if (!provider.hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Fim dos resultados',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _openDetail(BuildContext context, ScheduleModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleDetailScreen(scheduleId: item.id),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(label, style: AppTextStyles.sectionHeader),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Shimmer(width: 48, height: 14),
          SizedBox(height: 10),
          _Shimmer(width: 200, height: 12),
          SizedBox(height: 6),
          _Shimmer(width: 160, height: 12),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;

  const _Shimmer({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(4),
      ),
    );
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
            const Icon(Icons.wifi_off_rounded,
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined,
                size: 48, color: AppColors.textHint),
            SizedBox(height: 16),
            Text(
              'Nenhuma corrida encontrada\npara o período selecionado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
