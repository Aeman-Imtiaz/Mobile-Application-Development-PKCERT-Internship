import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: const AuthGate(),
    );
  }
}

/// Decides whether to show Login screen or the main app,
/// based on whether the user is currently signed in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen(); // Logged in
        }
        return const LoginScreen(); // Logged out
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Key _historyKey = UniqueKey();
  Key _summaryKey = UniqueKey();

  final List<String> _titles = ['Dashboard', 'History', 'Summary'];

  void _refreshData() {
    setState(() {
      _historyKey = UniqueKey();
      _summaryKey = UniqueKey();
    });
  }

  Future<void> _openAddExpense(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(initialType: type)),
    );
    if (result == true) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      HistoryScreen(key: _historyKey),
      SummaryScreen(key: _summaryKey),
    ];

    // The Dashboard tab has its own animated header, so we hide the
    // default AppBar there and let it show its own gradient header instead.
    final isDashboardTab = _currentIndex == 0;
    final isHistoryTab = _currentIndex == 1;

    return Scaffold(
      appBar: isDashboardTab
          ? null
          : AppBar(
              title: Text(_titles[_currentIndex]),
              actions: [
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'Ask Wise',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
      body: screens[_currentIndex],
      floatingActionButton: isHistoryTab
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'cashIn',
                  onPressed: () => _openAddExpense('cash_in'),
                  backgroundColor: Colors.green,
                  icon: const Icon(Icons.add),
                  label: const Text('Cash In'),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  heroTag: 'cashOut',
                  onPressed: () => _openAddExpense('cash_out'),
                  backgroundColor: Colors.red,
                  icon: const Icon(Icons.remove),
                  label: const Text('Cash Out'),
                ),
              ],
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Summary'),
        ],
      ),
    );
  }
}