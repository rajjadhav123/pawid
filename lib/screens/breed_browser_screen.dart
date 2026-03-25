import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';
import '../main.dart';
import '../models/breed_info.dart';
import '../models/detection_result.dart';
import '../widgets/shared_widgets.dart';
import 'result_screen.dart';

class BreedBrowserScreen extends StatefulWidget {
  const BreedBrowserScreen({super.key});

  @override
  State<BreedBrowserScreen> createState() => _BreedBrowserScreenState();
}

class _BreedBrowserScreenState extends State<BreedBrowserScreen> {
  List<String> _allBreeds = [];
  List<String> _filtered = [];
  bool _loading = true;
  bool _indianOnly = false;
  bool _initialized = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadBreeds();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBreeds() async {
    try {
      final breeds = await AppState.of(context).api.getAllBreeds();
      setState(() {
        _allBreeds = breeds;
        _filtered = breeds;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load breeds: $e'), backgroundColor: kRed),
        );
      }
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _allBreeds.where((b) {
        final matchesQuery = q.isEmpty || b.toLowerCase().contains(q);
        final matchesIndian = !_indianOnly ||
            kIndianBreeds.any((i) => i.toLowerCase() == b.toLowerCase());
        return matchesQuery && matchesIndian;
      }).toList();
    });
  }

  void _toggleIndian() {
    _indianOnly = !_indianOnly;
    _applyFilter();
  }

  Future<void> _openBreed(String breedName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: kAmber)),
    );
    try {
      final info = await AppState.of(context).api.getBreedInfo(breedName);
      if (!mounted) return;
      Navigator.pop(context); // dismiss loader
      // Wrap in a fake DetectionResult (no predictions/gradcam)
      final fakeResult = DetectionResult(
        success: true,
        breedInfo: info,
      );
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ResultScreen(result: fakeResult)));
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: kRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Breed Browser',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, color: kBrown)),
      ),
      body: Column(
        children: [
          // Search + filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search 149 breeds…',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: kMuted, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _applyFilter();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleIndian,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: _indianOnly ? kAmber : kWarm,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('🇮🇳',
                        style: TextStyle(
                            fontSize: 20,
                            color: _indianOnly ? Colors.white : null)),
                  ),
                ),
              ],
            ),
          ),
          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} breed${_filtered.length == 1 ? '' : 's'}',
                  style: GoogleFonts.spaceMono(fontSize: 10, color: kMuted),
                ),
                if (_indianOnly) ...[
                  const SizedBox(width: 8),
                  TagChip(
                      label: 'Indian breeds only',
                      bg: kWarm,
                      fg: kBrown2),
                ]
              ],
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kAmber))
                : _filtered.isEmpty
                    ? Center(
                        child: Text('No breeds found',
                            style: GoogleFonts.dmSans(color: kMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) =>
                            _BreedListTile(
                              name: _filtered[i],
                              onTap: () => _openBreed(_filtered[i]),
                            ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Breed List Tile ──────────────────────────────────────────────────────────

class _BreedListTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _BreedListTile({required this.name, required this.onTap});

  bool get _isIndian => kIndianBreeds
      .any((b) => b.toLowerCase() == name.toLowerCase());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: kBrown.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const Text('🐕', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kDark),
              ),
            ),
            if (_isIndian)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('🇮🇳', style: TextStyle(fontSize: 16)),
              ),
            const Icon(Icons.chevron_right_rounded, color: kMuted2, size: 20),
          ],
        ),
      ),
    );
  }
}