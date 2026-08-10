import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../db/database_helper.dart';
import '../services/pdf_service.dart';
import '../services/user_prefs_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _expenses = [];
  Map<String, double> _totals = {'cashIn': 0, 'cashOut': 0, 'balance': 0};
  double? _monthlyBudget;
  double? _dailyBudget;
  double _todaySpent = 0;
  bool _isLoading = true;
  bool _isExporting = false;
  InterstitialAd? _interstitialAd;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdService.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => debugPrint('Interstitial failed: $error'),
      ),
    );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final expenses = _searchQuery.isEmpty
        ? await DatabaseHelper.instance.getAllExpenses()
        : await DatabaseHelper.instance.searchExpenses(_searchQuery);
    final totals = await DatabaseHelper.instance.getTotals();
    final budget = await UserPrefsService.getMonthlyBudget();
    final dailyBudget = await UserPrefsService.getDailyBudget();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todaySpent = await DatabaseHelper.instance.getTodaySpent(todayStr);

    setState(() {
      _expenses = expenses;
      _totals = totals;
      _monthlyBudget = budget;
      _dailyBudget = dailyBudget;
      _todaySpent = todaySpent;
      _isLoading = false;
    });
  }

  Future<void> _exportPdf() async {
    if (_expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries to export yet.')),
      );
      return;
    }
    setState(() => _isExporting = true);

    final user = FirebaseAuth.instance.currentUser;
    final userName = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName!
        : (user?.email?.split('@').first ?? 'My');

    await PdfService.exportAndShare(
      userName: userName,
      expenses: _expenses,
      cashIn: _totals['cashIn']!,
      cashOut: _totals['cashOut']!,
      balance: _totals['balance']!,
    );

    if (mounted) setState(() => _isExporting = false);

    // Show interstitial after export completes (natural transition point)
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd(); // preload the next one
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Food': return Icons.fastfood;
      case 'Travel': return Icons.directions_bus;
      case 'Fuel': return Icons.local_gas_station;
      case 'Utilities': return Icons.bolt;
      case 'Shopping': return Icons.shopping_bag;
      case 'Bills': return Icons.receipt_long;
      case 'Entertainment': return Icons.movie;
      case 'Health': return Icons.local_hospital;
      case 'Income': return Icons.arrow_downward;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _summaryCard('Cash In', _totals['cashIn']!, Colors.green, Icons.arrow_downward)),
                      const SizedBox(width: 10),
                      Expanded(child: _summaryCard('Cash Out', _totals['cashOut']!, Colors.red, Icons.arrow_upward)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _summaryCard('Net Balance', _totals['balance']!, Colors.indigo, Icons.account_balance_wallet, fullWidth: true),

                  if (_dailyBudget != null && _dailyBudget! > 0) ...[
                    const SizedBox(height: 10),
                    _buildBudgetProgress('Daily Budget', _todaySpent, _dailyBudget!),
                  ],
                  if (_monthlyBudget != null && _monthlyBudget! > 0) ...[
                    const SizedBox(height: 10),
                    _buildBudgetProgress('Monthly Budget', _totals['cashOut']!, _monthlyBudget!),
                  ],

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by description or category...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onChanged: (value) {
                            _searchQuery = value;
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: IconButton(
                          onPressed: _isExporting ? null : _exportPdf,
                          tooltip: 'Download PDF Report',
                          icon: _isExporting
                              ? const SizedBox(
                                  height: 18, width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.picture_as_pdf_outlined, color: Colors.indigo),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_expenses.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No entries found.\nTap + to add your first one!',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            )
          else
            _buildGroupedList(),

          // Extra bottom padding so the last item isn't hidden behind the
          // Cash In / Cash Out floating buttons.
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double amount, Color color, IconData icon, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('Rs. ${amount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: amount < 0 ? Colors.red : Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(String label, double spent, double budget) {
    final percent = (spent / budget).clamp(0.0, 1.5);
    final isOver = spent > budget;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(
                'Rs. ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, color: isOver ? Colors.red : Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent > 1 ? 1 : percent,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: isOver ? Colors.red : Colors.green,
            ),
          ),
          if (isOver) ...[
            const SizedBox(height: 6),
            Text('⚠️ $label se zyada kharch ho chuka hai!', style: const TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final e in _expenses) {
      final date = e['date'] as String;
      grouped.putIfAbsent(date, () => []).add(e);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final date = sortedDates[index];
          final items = grouped[date]!;
          final dayNet = items.fold<double>(
            0, (sum, e) => sum + (e['type'] == 'cash_in' ? (e['amount'] as double) : -(e['amount'] as double)));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd MMM yyyy').format(DateTime.parse(date)),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text('Rs. ${dayNet.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: dayNet < 0 ? Colors.red : Colors.green)),
                  ],
                ),
              ),
              ...items.map((e) {
                final isCashIn = e['type'] == 'cash_in';
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isCashIn ? Colors.green : Colors.red).withValues(alpha: 0.15),
                      child: Icon(_iconForCategory(e['category'] as String),
                          color: isCashIn ? Colors.green : Colors.red),
                    ),
                    title: Text(e['description'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${e['category']}${(e['contactName'] as String?)?.isNotEmpty == true ? " • ${e['contactName']}" : ""} • ${e['paymentMode']}',
                    ),
                    trailing: Text(
                      '${isCashIn ? '+' : '-'} Rs. ${(e['amount'] as double).toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isCashIn ? Colors.green : Colors.red),
                    ),
                    onLongPress: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Entry'),
                          content: const Text('Are you sure you want to delete this entry?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await DatabaseHelper.instance.deleteExpense(e['id'] as int);
                        _loadData();
                      }
                    },
                  ),
                );
              }),
            ],
          );
        },
        childCount: sortedDates.length,
      ),
    );
  }
}