import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';
import '../main.dart';
import '../widgets/shared_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlCtrl;
  bool _testing = false;
  String? _testResult;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _urlCtrl.text = AppState.of(context).serverUrl.value;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final api = AppState.of(context).api;
      final health = await api.checkHealth();
      setState(() {
        _testResult =
            '✅ Connected! ${health.totalBreeds} breeds · ${health.demoMode ? "Demo Mode" : "Model loaded"}';
        _testing = false;
      });
      AppState.of(context).serverOnline.value = true;
    } catch (e) {
      setState(() {
        _testResult =
            '❌ ${e.toString().replaceFirst('ApiException: ', '')}';
        _testing = false;
      });
      AppState.of(context).serverOnline.value = false;
    }
  }

  void _save() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    // Remove trailing slash
    final cleaned = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    AppState.of(context).serverUrl.value = cleaned;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Server URL saved'), backgroundColor: kGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, color: kBrown)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kBrown),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Server Configuration'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: kBrown.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Base URL',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kBrown),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _urlCtrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      hintText: 'http://192.168.1.x:5000',
                      prefixIcon:
                          Icon(Icons.link_rounded, color: kMuted, size: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: _testing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: kAmber))
                              : const Icon(Icons.wifi_tethering_rounded,
                                  size: 16, color: kAmber),
                          label: Text('Test',
                              style: GoogleFonts.dmSans(
                                  color: kAmber,
                                  fontWeight: FontWeight.w600)),
                          onPressed: _testing ? null : _testConnection,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kAmber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_outlined, size: 16),
                          label: const Text('Save'),
                          onPressed: _save,
                        ),
                      ),
                    ],
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _testResult!.startsWith('✅')
                            ? kGreenBg
                            : kRedBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _testResult!,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _testResult!.startsWith('✅')
                              ? kGreen
                              : kRed,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SectionHeader('Preset URLs'),
            ...[
              ('Android Emulator', 'http://10.0.2.2:5000'),
              ('iOS Simulator', 'http://127.0.0.1:5000'),
              ('Render Deploy', 'https://pawid.onrender.com'),
            ].map(
              (p) => ListTile(
                title: Text(p.$1,
                    style: GoogleFonts.dmSans(fontSize: 13, color: kDark)),
                subtitle: Text(p.$2,
                    style: GoogleFonts.spaceMono(
                        fontSize: 10, color: kMuted2)),
                contentPadding: EdgeInsets.zero,
                trailing: TextButton(
                  onPressed: () {
                    _urlCtrl.text = p.$2;
                  },
                  child: Text('Use',
                      style: GoogleFonts.dmSans(
                          color: kAmber, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SectionHeader('About'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AboutRow('App', 'PawID v1.0'),
                  _AboutRow('Model', 'MobileNetV2 · 120 classes'),
                  _AboutRow('Database', '149 breeds'),
                  _AboutRow('PawBot', 'Groq · Llama 3.1'),
                  _AboutRow('Author', 'Raj Jadhav'),
                  _AboutRow('LICIENSE', '© 2026 Raj Jadhav · MIT License'),


                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: GoogleFonts.spaceMono(fontSize: 10, color: kMuted2))),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
        ],
      ),
    );
  }
}