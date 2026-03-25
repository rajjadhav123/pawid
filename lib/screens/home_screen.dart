import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../config/constants.dart';
import '../main.dart';
import '../models/detection_result.dart';
import '../models/history_entry.dart';
import '../widgets/shared_widgets.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  // ─── Pick & Detect ──────────────────────────────────────────────────────────

  Future<void> _pickAndDetect(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (xfile == null) return;
      await _runDetection(File(xfile.path));
    } catch (e) {
      _showError('Could not open image: $e');
    }
  }

  Future<void> _runDetection(File imageFile) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final appState = AppState.of(context);
      final result = await appState.api.detectBreed(imageFile);

      if (!mounted) return;

      if (result.notADog) {
        _showNotADogError(result.error);
        return;
      }

      if (!result.success) {
        _showError(result.error ?? 'Detection failed. Please try again.');
        return;
      }

      // Save to history
      await _saveToHistory(result, imageFile);

      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultScreen(result: result, imageFile: imageFile),
      ));
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveToHistory(DetectionResult result, File imageFile) async {
    final appState = AppState.of(context);
    final top = result.topPrediction;
    if (top == null || result.breedInfo == null) return;

    // Thumbnail: read bytes and store as base64
    String? thumb;
    try {
      final bytes = await imageFile.readAsBytes();
      thumb = base64Encode(bytes);
    } catch (_) {}

    final entry = HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      breed: top.breed,
      confidence: top.confidence,
      percentage: top.percentage,
      emoji: result.breedInfo?.emoji ?? '🐕',
      origin: result.breedInfo?.origin,
      group: result.breedInfo?.group,
      alternatives: result.alternatives.take(2).map((p) => p.breed).toList(),
      imageBase64: thumb,
      isDemo: result.demoMode,
      timestamp: DateTime.now(),
    );

    await appState.historyService.addEntry(entry);
    // Reload history list
    final updated = await appState.historyService.loadHistory();
    appState.history.value = updated;
  }

  // ─── Error helpers ──────────────────────────────────────────────────────────

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNotADogError(String? message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🚫', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('Not a Dog',
                style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w700, color: kRed)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message ?? 'Could not detect a dog in that photo.',
              style: GoogleFonts.dmSans(color: kMuted),
            ),
            const SizedBox(height: 12),
            _tip('Use a clear, well-lit photo'),
            _tip('Dog should fill 60%+ of the frame'),
            _tip('Avoid screenshots or dark images'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Try Again',
                style: GoogleFonts.dmSans(
                    color: kAmber, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Text('• ', style: TextStyle(color: kAmber)),
            Text(text, style: GoogleFonts.dmSans(fontSize: 13, color: kMuted)),
          ],
        ),
      );

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🐾 '),
            Text('PawID',
                style: GoogleFonts.playfairDisplay(
                    color: kBrown, fontWeight: FontWeight.w800, fontSize: 24)),
          ],
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: AppState.of(context).serverOnline,
            builder: (_, online, __) =>
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(child: StatusDot(online: online)),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: kBrown),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: PawLoading(message: 'Identifying breed…'))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card
          _buildHeroCard(),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Upload Photo',
                  onTap: () => _pickAndDetect(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Take Photo',
                  onTap: () => _pickAndDetect(ImageSource.camera),
                  isPrimary: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Recent detections
          _buildRecentSection(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kBrown, kBrown2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kBrown.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🐕', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Identify Any\nDog Breed',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI-powered detection with India suitability scores',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kAmber.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '149 breeds · Grad-CAM · PawBot AI',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: kAmber2,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    return ValueListenableBuilder<List<HistoryEntry>>(
      valueListenable: AppState.of(context).history,
      builder: (_, history, __) {
        if (history.isEmpty) return const SizedBox.shrink();
        final recent = history.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Recent Detections'),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _RecentCard(entry: recent[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isPrimary ? kAmber : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(color: const Color(0xFFE8D8C4), width: 1.5),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: kAmber.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : kAmber, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : kBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent Card ──────────────────────────────────────────────────────────────

class _RecentCard extends StatelessWidget {
  final HistoryEntry entry;
  const _RecentCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: kBrown.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.emoji, style: const TextStyle(fontSize: 24)),
              ConfidenceBadge(confidence: entry.confidence),
            ],
          ),
          const Spacer(),
          Text(
            entry.breed,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kBrown,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            entry.timeAgo,
            style: GoogleFonts.dmSans(fontSize: 10, color: kMuted2),
          ),
        ],
      ),
    );
  }
}