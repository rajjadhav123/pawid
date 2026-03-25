import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/constants.dart';
import 'services/api_service.dart';
import 'services/history_service.dart';
import 'models/history_entry.dart';
import 'screens/home_screen.dart';
import 'screens/breed_browser_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final serverUrl = prefs.getString(kServerUrlKey) ?? kDefaultServerUrl;
  runApp(PawIDApp(initialServerUrl: serverUrl));
}

// ─── App-level state (simple InheritedWidget, no extra deps) ──────────────────

class AppState extends InheritedWidget {
  final PawIDApiService api;
  final HistoryService historyService;
  final ValueNotifier<String> serverUrl;
  final ValueNotifier<List<HistoryEntry>> history;
  final ValueNotifier<bool> serverOnline;

  const AppState({
    super.key,
    required this.api,
    required this.historyService,
    required this.serverUrl,
    required this.history,
    required this.serverOnline,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppState>();
    assert(result != null, 'No AppState found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppState old) => false;
}

// ─── Root widget ──────────────────────────────────────────────────────────────

class PawIDApp extends StatefulWidget {
  final String initialServerUrl;
  const PawIDApp({super.key, required this.initialServerUrl});

  @override
  State<PawIDApp> createState() => _PawIDAppState();
}

class _PawIDAppState extends State<PawIDApp> {
  late final ValueNotifier<String> _serverUrl;
  late final ValueNotifier<List<HistoryEntry>> _history;
  late final ValueNotifier<bool> _serverOnline;
  late PawIDApiService _api;
  final HistoryService _historyService = HistoryService();

  @override
  void initState() {
    super.initState();
    _serverUrl = ValueNotifier(widget.initialServerUrl);
    _history = ValueNotifier([]);
    _serverOnline = ValueNotifier(false);
    _api = PawIDApiService(baseUrl: widget.initialServerUrl);

    _serverUrl.addListener(() {
      _api = PawIDApiService(baseUrl: _serverUrl.value);
      _historyService.setServerUrl(_serverUrl.value);
      _checkHealth();
    });

    _loadHistory();
    _checkHealth();
  }

  Future<void> _loadHistory() async {
    final entries = await _historyService.loadHistory();
    _history.value = entries;
  }

  Future<void> _checkHealth() async {
    try {
      await _api.checkHealth();
      _serverOnline.value = true;
    } catch (_) {
      _serverOnline.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppState(
      api: _api,
      historyService: _historyService,
      serverUrl: _serverUrl,
      history: _history,
      serverOnline: _serverOnline,
      child: MaterialApp(
        title: 'PawID',
        debugShowCheckedModeBanner: false,
        theme: pawIDTheme(),
        home: const MainShell(),
      ),
    );
  }
}

// ─── Main shell with bottom nav ───────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    BreedBrowserScreen(),
    AnalyticsScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: AppState.of(context).serverOnline,
        builder: (context, online, _) {
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                label: 'Detect',
              ),
              NavigationDestination(
                icon: Icon(Icons.pets_rounded),
                label: 'Breeds',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded),
                label: 'Analytics',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
                label: 'History',
              ),
            ],
          );
        },
      ),
    );
  }
}