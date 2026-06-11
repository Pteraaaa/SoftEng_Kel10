import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/Services/AuthService.dart';

class CategoryAnalytics {
  final String categoryName;
  final double percentage;
  final double amount;
  final Color color;
  final IconData icon;

  const CategoryAnalytics({
    required this.categoryName,
    required this.percentage,
    required this.amount,
    required this.color,
    required this.icon,
  });

  factory CategoryAnalytics.fromApi(Map<String, dynamic> data, int index) {
    final color = _parseColor(
      data["category_color_hex"]?.toString() ?? "",
      fallback: _fallbackColors[index % _fallbackColors.length],
    );

    return CategoryAnalytics(
      categoryName: data["category_name"]?.toString() ?? "Uncategorized",
      percentage: _toDouble(data["percentage"]),
      amount: _toDouble(data["total_amount"]),
      color: color,
      icon: _iconFor(data["category_icon_url"]?.toString() ?? ""),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "") ?? 0;
  }

  static Color _parseColor(String value, {required Color fallback}) {
    final hex = value.replaceFirst("#", "");
    final parsed = int.tryParse(hex.length == 6 ? "FF$hex" : hex, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  static IconData _iconFor(String iconName) {
    switch (iconName) {
      case "ic_restaurant":
      case "restaurant":
        return Icons.restaurant;
      case "ic_shopping_cart":
      case "shopping_cart":
        return Icons.shopping_bag_outlined;
      case "ic_work":
      case "work":
        return Icons.work_outline;
      case "ic_movie":
      case "movie":
        return Icons.movie_outlined;
      case "ic_directions_car":
      case "transport":
        return Icons.directions_car_outlined;
      case "ic_home":
        return Icons.home_outlined;
      default:
        return Icons.payments_outlined;
    }
  }
}

class AnalyticsData {
  final String period;
  final double totalExpense;
  final List<CategoryAnalytics> categories;

  const AnalyticsData({
    required this.period,
    required this.totalExpense,
    required this.categories,
  });

  factory AnalyticsData.fromApi(Map<String, dynamic> data) {
    final rows = data["data"];
    final categories = rows is List
        ? rows
              .whereType<Map<String, dynamic>>()
              .toList()
              .asMap()
              .entries
              .map((entry) => CategoryAnalytics.fromApi(entry.value, entry.key))
              .toList()
        : <CategoryAnalytics>[];

    return AnalyticsData(
      period: data["period"]?.toString() ?? "all",
      totalExpense: CategoryAnalytics._toDouble(data["grand_total_expense"]),
      categories: categories,
    );
  }
}

const _fallbackColors = [
  Color(0xFFEF4444),
  Color(0xFF2563EB),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFF0F766E),
];

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<AnalyticsData> analyticsFuture;
  int selectedFilter = 1;

  final filters = const [
    ("Week", "week"),
    ("Month", "month"),
    ("Year", "year"),
  ];

  @override
  void initState() {
    super.initState();
    analyticsFuture = _fetchAnalytics();
  }

  Future<AnalyticsData> _fetchAnalytics() async {
    final data = await AuthService.getCategoryBreakdown(
      period: filters[selectedFilter].$2,
    );
    return AnalyticsData.fromApi(data);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<AnalyticsData>(
        future: analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(onRetry: _reload);
          }

          final analytics =
              snapshot.data ??
              const AnalyticsData(
                period: "month",
                totalExpense: 0,
                categories: [],
              );

          final topCategory = analytics.categories.isEmpty
              ? null
              : analytics.categories.reduce(
                  (a, b) => a.amount > b.amount ? a : b,
                );

          return RefreshIndicator(
            onRefresh: _reload,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Analytics",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Expense composition by category",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 18),
                  _FilterSegment(
                    filters: filters,
                    selectedIndex: selectedFilter,
                    onChanged: (index) {
                      setState(() {
                        selectedFilter = index;
                        analyticsFuture = _fetchAnalytics();
                      });
                    },
                  ),
                  const SizedBox(height: 22),
                  _SummaryPanel(
                    totalExpense: analytics.totalExpense,
                    period: filters[selectedFilter].$1,
                    topCategory: topCategory,
                    categoryCount: analytics.categories.length,
                  ),
                  const SizedBox(height: 22),
                  if (analytics.categories.isEmpty)
                    const _EmptyAnalytics()
                  else ...[
                    Center(
                      child: AnalyticsDonutChart(
                        analytics: analytics.categories,
                        topCategory: topCategory!,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      "CATEGORY BREAKDOWN",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...analytics.categories.map(CategoryCard.new),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _reload() async {
    setState(() {
      analyticsFuture = _fetchAnalytics();
    });
    await analyticsFuture;
  }
}

class _FilterSegment extends StatelessWidget {
  final List<(String, String)> filters;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _FilterSegment({
    required this.filters,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final isSelected = selectedIndex == entry.key;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(entry.key),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  entry.value.$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final double totalExpense;
  final String period;
  final CategoryAnalytics? topCategory;
  final int categoryCount;

  const _SummaryPanel({
    required this.totalExpense,
    required this.period,
    required this.topCategory,
    required this.categoryCount,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total expense this ${period.toLowerCase()}",
            style: const TextStyle(color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(totalExpense),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MetricPill(
                icon: Icons.leaderboard_outlined,
                label: topCategory?.categoryName ?? "No category",
              ),
              const SizedBox(width: 10),
              _MetricPill(
                icon: Icons.category_outlined,
                label: "$categoryCount categories",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFC107), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsDonutChart extends StatelessWidget {
  final List<CategoryAnalytics> analytics;
  final CategoryAnalytics topCategory;

  const AnalyticsDonutChart({
    super.key,
    required this.analytics,
    required this.topCategory,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(240, 240),
            painter: DonutChartPainter(analytics),
          ),
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "TOP SPEND",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    topCategory.categoryName,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${topCategory.percentage.toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: topCategory.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<CategoryAnalytics> analytics;

  DonutChartPainter(this.analytics);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 22.0;
    final radius = size.width / 2;
    var startAngle = -90.0;

    final background = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(radius, radius), radius - strokeWidth, background);

    for (final item in analytics) {
      final sweepAngle = 360 * (item.percentage / 100);
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(radius, radius),
          radius: radius - strokeWidth,
        ),
        _radians(startAngle),
        _radians(sweepAngle),
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  double _radians(double degree) => degree * 3.14159265359 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CategoryCard extends StatelessWidget {
  final CategoryAnalytics analytics;

  const CategoryCard(this.analytics, {super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: analytics.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(analytics.icon, color: analytics.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        analytics.categoryName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      currency.format(analytics.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: analytics.percentage / 100,
                    minHeight: 8,
                    backgroundColor: analytics.color.withOpacity(0.13),
                    valueColor: AlwaysStoppedAnimation(analytics.color),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  "${analytics.percentage.toStringAsFixed(1)}% of spending",
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.donut_large_outlined,
            color: Colors.grey.shade400,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            "No expense data yet",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            "Create an expense transaction to populate this breakdown.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 42),
            const SizedBox(height: 10),
            const Text("Failed to load analytics"),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text("Try Again")),
          ],
        ),
      ),
    );
  }
}
