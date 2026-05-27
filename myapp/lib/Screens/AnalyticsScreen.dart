import 'package:flutter/material.dart';

///
/// MODEL
///
class CategoryAnalytics {
  final String categoryName;
  final double percentage;
  final double amount;
  final int transactionCount;
  final Color color;
  final IconData icon;

  const CategoryAnalytics({
    required this.categoryName,
    required this.percentage,
    required this.amount,
    required this.transactionCount,
    required this.color,
    required this.icon,
  });
}

///
/// REPOSITORY
/// Backend Ready
/// Replace with Firebase / API later
///
class AnalyticsRepository {
  Future<List<CategoryAnalytics>> fetchAnalytics() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      CategoryAnalytics(
        categoryName: "Shopping",
        percentage: 35,
        amount: 900000,
        transactionCount: 12,
        color: Colors.orange,
        icon: Icons.shopping_bag_outlined,
      ),

      CategoryAnalytics(
        categoryName: "Transport",
        percentage: 25,
        amount: 500000,
        transactionCount: 8,
        color: Colors.blue,
        icon: Icons.directions_bus_outlined,
      ),

      CategoryAnalytics(
        categoryName: "Food",
        percentage: 20,
        amount: 350000,
        transactionCount: 10,
        color: Colors.green,
        icon: Icons.fastfood_outlined,
      ),

      CategoryAnalytics(
        categoryName: "Entertainment",
        percentage: 20,
        amount: 400000,
        transactionCount: 5,
        color: Colors.red,
        icon: Icons.movie_outlined,
      ),
    ];
  }
}

///
/// ANALYTICS SCREEN
///
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsRepository repository = AnalyticsRepository();

  late Future<List<CategoryAnalytics>> analyticsFuture;

  int selectedFilter = 1;

  @override
  void initState() {
    super.initState();

    analyticsFuture = repository.fetchAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<CategoryAnalytics>>(
        future: analyticsFuture,
        builder: (context, snapshot) {
          ///
          /// LOADING
          ///
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          ///
          /// ERROR
          ///
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          ///
          /// DATA
          ///
          final analytics = snapshot.data ?? [];

          final totalSpent = analytics.fold<double>(
            0,
            (sum, item) => sum + item.amount,
          );

          final topSpend = analytics.reduce(
            (a, b) => a.percentage > b.percentage ? a : b,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///
                /// HEADER
                ///
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Analytics",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                ///
                /// FILTER BUTTONS
                ///
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      buildFilterButton("Week", 0),

                      buildFilterButton("Month", 1),

                      buildFilterButton("Year", 2),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                ///
                /// TOTAL SPENT
                ///
                Center(
                  child: Column(
                    children: [
                      Text(
                        formatCurrency(totalSpent),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Total spent this month",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                ///
                /// DONUT CHART
                ///
                Center(
                  child: AnalyticsDonutChart(
                    analytics: analytics,
                    topCategory: topSpend,
                  ),
                ),

                const SizedBox(height: 28),

                ///
                /// CATEGORY TITLE
                ///
                Text(
                  "TRANSACTION PER CATEGORY",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 14),

                ///
                /// CATEGORY LIST
                ///
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: analytics.length,
                  itemBuilder: (context, index) {
                    return CategoryCard(analytics: analytics[index]);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ///
  /// FILTER BUTTON
  ///
  Widget buildFilterButton(String title, int index) {
    final isSelected = selectedFilter == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///
  /// FORMAT CURRENCY
  ///
  String formatCurrency(double amount) {
    return "Rp${amount.toStringAsFixed(0)}";
  }
}

///
/// DONUT CHART
///
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
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ///
          /// CHART
          ///
          CustomPaint(
            size: const Size(220, 220),
            painter: DonutChartPainter(analytics),
          ),

          ///
          /// CENTER TEXT
          ///
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "TOP SPEND",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                topCategory.categoryName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "${topCategory.percentage.toInt()}%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: topCategory.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

///
/// DONUT CHART PAINTER
///
class DonutChartPainter extends CustomPainter {
  final List<CategoryAnalytics> analytics;

  DonutChartPainter(this.analytics);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 22.0;

    final radius = size.width / 2;

    double startAngle = -90;

    for (var item in analytics) {
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
        radians(startAngle),
        radians(sweepAngle),
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  double radians(double degree) {
    return degree * 3.14159265359 / 180;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

///
/// CATEGORY CARD
///
class CategoryCard extends StatelessWidget {
  final CategoryAnalytics analytics;

  const CategoryCard({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ///
          /// ICON
          ///
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: analytics.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(analytics.icon, color: analytics.color),
          ),

          const SizedBox(width: 14),

          ///
          /// DETAILS
          ///
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///
                /// NAME + AMOUNT
                ///
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      analytics.categoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    Text(
                      formatCurrency(analytics.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                ///
                /// PROGRESS BAR
                ///
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: analytics.percentage / 100,
                          minHeight: 7,
                          backgroundColor: analytics.color.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(analytics.color),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Text(
                      "${analytics.percentage.toInt()}%",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                ///
                /// TRANSACTION COUNT
                ///
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${analytics.transactionCount}x Transactions",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ///
  /// FORMAT CURRENCY
  ///
  String formatCurrency(double amount) {
    return "Rp${amount.toStringAsFixed(0)}";
  }
}
