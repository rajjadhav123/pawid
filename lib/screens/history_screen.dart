import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';
import '../main.dart';
import '../models/history_entry.dart';
import '../widgets/shared_widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _clearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear History',
            style: GoogleFonts.playfairDisplay(
                color: kBrown, fontWeight: FontWeight.w700)),
        content: Text('Delete all detection history? This cannot be undone.',
            style: GoogleFonts.dmSans(color: kMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.dmSans(color: kMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Clear All',
                  style: GoogleFonts.dmSans(
                      color: kRed, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed != true) return;

    final appState = AppState.of(context);
    await appState.historyService.clearAll();
    appState.history.value = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, color: kBrown)),
        actions: [
          ValueListenableBuilder<List<HistoryEntry>>(
            valueListenable: AppState.of(context).history,
            builder: (_, history, __) => history.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: kRed),
                    onPressed: () => _clearAll(context),
                    tooltip: 'Clear all',
                  ),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<HistoryEntry>>(
        valueListenable: AppState.of(context).history,
        builder: (_, history, __) {
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🐾', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No detections yet',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 18, color: kBrown)),
                  const SizedBox(height: 6),
                  Text('Identify a dog breed to see it here',
                      style: GoogleFonts.dmSans(color: kMuted)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: history.length,
            itemBuilder: (ctx, i) => _HistoryCard(entry: history[i]),
          );
        },
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: kBrown.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: entry.imageBase64 != null
                  ? Image.memory(
                      base64Decode(entry.imageBase64!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.emoji,
                        style: const TextStyle(fontSize: 18)),
                    ConfidenceBadge(confidence: entry.confidence),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.breed,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kBrown),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.timeAgo,
                  style: GoogleFonts.dmSans(fontSize: 10, color: kMuted2),
                ),
                if (entry.isDemo)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TagChip(
                        label: 'Demo', bg: kYellowBg, fg: kYellow),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: kWarm,
        child: const Center(
          child: Text('🐕', style: TextStyle(fontSize: 32)),
        ),
      );
}