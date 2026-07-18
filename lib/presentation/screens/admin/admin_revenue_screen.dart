import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/local/database_helper.dart';

final revenueStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(dbProvider).getRevenueStats();
});

class AdminRevenueScreen extends ConsumerStatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  ConsumerState<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends ConsumerState<AdminRevenueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(revenueStatsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(revenueStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê doanh thu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(revenueStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(revenueStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Tổng quan
              Row(children: [
                Expanded(
                  child: _StatCard(
                    title: 'Tổng doanh thu',
                    value: CurrencyFormatter.formatVND(stats['totalRevenue'] as double),
                    icon: Icons.attach_money,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Tháng này',
                    value: CurrencyFormatter.formatVND(stats['monthRevenue'] as double),
                    icon: Icons.calendar_month,
                    color: Colors.green,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _StatCard(
                    title: 'Tổng đơn hàng',
                    value: '${stats['totalOrders']}',
                    icon: Icons.receipt_long,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Chờ xác nhận',
                    value: '${stats['pendingOrders']}',
                    icon: Icons.pending_actions,
                    color: Colors.red,
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // Doanh thu theo danh mục
              const Text('Doanh thu theo danh mục',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _CategoryRevenueCard(
                  revenueByCategory: Map<String, double>.from(
                      stats['revenueByCategory'] as Map)),

              const SizedBox(height: 20),

              // Doanh thu theo ngày trong tháng
              const Text('Doanh thu theo ngày (tháng này)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _DailyRevenueCard(
                  revenueByDay:
                      Map<String, double>.from(stats['revenueByDay'] as Map)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }
}

class _CategoryRevenueCard extends StatelessWidget {
  final Map<String, double> revenueByCategory;
  const _CategoryRevenueCard({required this.revenueByCategory});

  static const _catNames = {
    'cpu': 'CPU',
    'gpu': 'GPU',
    'ram': 'RAM',
    'ssd': 'SSD',
    'motherboard': 'Mainboard',
    'psu': 'PSU',
    'case': 'Case',
    'cooling': 'Cooling',
    'other': 'Khác',
  };

  @override
  Widget build(BuildContext context) {
    if (revenueByCategory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Text('Chưa có dữ liệu',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final total =
        revenueByCategory.values.fold<double>(0, (s, v) => s + v);
    final sorted = revenueByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)]),
      child: Column(
        children: sorted.map((e) {
          final pct = total > 0 ? e.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_catNames[e.key] ?? e.key,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(CurrencyFormatter.formatVND(e.value),
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(pct * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

class _DailyRevenueCard extends StatelessWidget {
  final Map<String, double> revenueByDay;
  const _DailyRevenueCard({required this.revenueByDay});

  @override
  Widget build(BuildContext context) {
    if (revenueByDay.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Text('Chưa có doanh thu trong tháng này',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final maxVal =
        revenueByDay.values.fold<double>(0, (m, v) => v > m ? v : m);
    final sorted = revenueByDay.entries.toList()
      ..sort((a, b) {
        final aDay = int.tryParse(a.key.split('/').first) ?? 0;
        final bDay = int.tryParse(b.key.split('/').first) ?? 0;
        return aDay.compareTo(bDay);
      });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)]),
      child: Column(
        children: sorted.map((e) {
          final pct = maxVal > 0 ? e.value / maxVal : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                  width: 48,
                  child: Text(e.key,
                      style: const TextStyle(fontSize: 12, color: Colors.grey))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 20,
                    backgroundColor: Colors.grey.shade100,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: Text(
                  CurrencyFormatter.formatVND(e.value),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green),
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}
