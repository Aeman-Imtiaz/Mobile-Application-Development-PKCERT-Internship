import 'package:flutter/material.dart';
import '../services/user_prefs_service.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _monthlyBudgetController = TextEditingController();
  final _dailyBudgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final monthly = await UserPrefsService.getMonthlyBudget();
    final daily = await UserPrefsService.getDailyBudget();
    if (monthly != null) _monthlyBudgetController.text = monthly.toStringAsFixed(0);
    if (daily != null) _dailyBudgetController.text = daily.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _saveBudgets() async {
    final monthly = double.tryParse(_monthlyBudgetController.text.trim());
    final daily = double.tryParse(_dailyBudgetController.text.trim());

    if (monthly != null) await UserPrefsService.setMonthlyBudget(monthly);
    if (daily != null) await UserPrefsService.setDailyBudget(daily);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budgets updated'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            child: ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.indigo),
              title: const Text('Edit Profile'),
              subtitle: const Text('Name, email, age, picture'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ),
          const SizedBox(height: 16),

          _sectionCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.savings_outlined, color: Colors.indigo),
                      SizedBox(width: 10),
                      Text('Budget Limits', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Get notified when you overspend', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 14),

                  Text('Monthly Budget', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _monthlyBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: 'Rs. ',
                      hintText: 'e.g. 30000',
                      filled: true, fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Daily Budget', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _dailyBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: 'Rs. ',
                      hintText: 'e.g. 1500',
                      filled: true, fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: _saveBudgets,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Budgets'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _sectionCard(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.indigo),
                  title: Text('About SpendWise'),
                  subtitle: Text('Version 1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () => AuthService().logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }
}