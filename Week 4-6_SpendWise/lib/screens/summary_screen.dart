import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../db/database_helper.dart';
import '../services/ad_service.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _categoryTotals = [];
  bool _isLoading = true;

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  final List<Color> _colors = [
    Colors.blue, Colors.orange, Colors.green, Colors.purple,
    Colors.red, Colors.teal, Colors.amber, Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final yearMonth = DateFormat('yyyy-MM').format(_selectedMonth);
    final data = await DatabaseHelper.instance.getCategoryTotals(yearMonth);
    setState(() {
      _categoryTotals = data;
      _isLoading = false;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
    _loadData();
  }

  double get _total =>
      _categoryTotals.fold(0.0, (sum, e) => sum + (e['total'] as num).toDouble());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month selector
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _categoryTotals.isEmpty
                  ? const Center(
                      child: Text(
                        'No expenses this month.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Total spending
                          Text(
                            'Total: Rs. ${_total.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // Pie Chart
                          SizedBox(
                            height: 240,
                            child: PieChart(
                              PieChartData(
                                sections: List.generate(_categoryTotals.length, (i) {
                                  final item = _categoryTotals[i];
                                  final total = (item['total'] as num).toDouble();
                                  final percent = (total / _total * 100);
                                  return PieChartSectionData(
                                    value: total,
                                    color: _colors[i % _colors.length],
                                    title: '${percent.toStringAsFixed(0)}%',
                                    radius: 90,
                                    titleStyle: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white,
                                    ),
                                  );
                                }),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Legend / category breakdown list
                          ...List.generate(_categoryTotals.length, (i) {
                            final item = _categoryTotals[i];
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 8,
                                backgroundColor: _colors[i % _colors.length],
                              ),
                              title: Text(item['category'] as String),
                              trailing: Text(
                                'Rs. ${(item['total'] as num).toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
        ),

        // Banner ad at the bottom — safe here since Summary has no floating buttons.
        if (_isBannerLoaded && _bannerAd != null)
          Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
      ],
    );
  }
}