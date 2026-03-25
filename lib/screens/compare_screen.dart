import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';
import '../main.dart';
import '../models/breed_info.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

class CompareScreen extends StatefulWidget {
  final String? prefillBreed;
  const CompareScreen({super.key, this.prefillBreed});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  List<String> _allBreeds = [];
  String? _breed1;
  String? _breed2;
  CompareResult? _result;
  bool _loading = false;
  bool _loadingBreeds = true;

  @override
  void initState() {
    super.initState();
    _breed1 = widget.prefillBreed;
    _loadBreeds();
  }

  Future<void> _loadBreeds() async {
    try {
      final breeds = await AppState.of(context).api.getAllBreeds();
      setState(() {
        _allBreeds = breeds;
        _loadingBreeds = false;
      });
    } catch (_) {
      setState(() => _loadingBreeds = false);
    }
  }

  Future<void> _compare() async {
    if (_breed1 == null || _breed2 == null) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final res =
          await AppState.of(context).api.compareBreeds(_breed1!, _breed2!);
      setState(() {
        _result = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
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
        title: Text('Compare Breeds',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, color: kBrown)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kBrown),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingBreeds
          ? const Center(child: CircularProgressIndicator(color: kAmber))
          : Column(
              children: [
                // Selectors
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                          child:
                              _BreedDropdown(
                        label: 'Breed 1',
                        value: _breed1,
                        breeds: _allBreeds,
                        onChanged: (v) => setState(() => _breed1 = v),
                      )),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('vs',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, color: kMuted)),
                      ),
                      Expanded(
                          child: _BreedDropdown(
                        label: 'Breed 2',
                        value: _breed2,
                        breeds: _allBreeds,
                        onChanged: (v) => setState(() => _breed2 = v),
                      )),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_breed1 != null &&
                              _breed2 != null &&
                              _breed1 != _breed2 &&
                              !_loading)
                          ? _compare
                          : null,
                      child: _loading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Compare'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_result != null) Expanded(child: _CompareTable(result: _result!)),
              ],
            ),
    );
  }
}

// ─── Breed Dropdown ───────────────────────────────────────────────────────────

class _BreedDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> breeds;
  final ValueChanged<String?> onChanged;

  const _BreedDropdown({
    required this.label,
    required this.value,
    required this.breeds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      style: GoogleFonts.dmSans(fontSize: 13, color: kDark),
      items: breeds
          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─── Compare Table ────────────────────────────────────────────────────────────

class _CompareTable extends StatelessWidget {
  final CompareResult result;
  const _CompareTable({required this.result});

  @override
  Widget build(BuildContext context) {
    final b1 = result.breed1;
    final b2 = result.breed2;

    final rows = _buildRows(b1, b2);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Header
          _CompareHeader(b1: b1, b2: b2),
          const SizedBox(height: 8),
          ...rows.map((r) => _CompareRow(row: r)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<_RowData> _buildRows(BreedInfo b1, BreedInfo b2) {
    return [
      _RowData.text('Origin', b1.origin, b2.origin),
      _RowData.text('Group', b1.group, b2.group),
      _RowData.text('Size', b1.size, b2.size),
      _RowData.text('Weight', b1.weightKg != null ? '${b1.weightKg} kg' : null,
          b2.weightKg != null ? '${b2.weightKg} kg' : null),
      _RowData.text('Lifespan', b1.lifespan, b2.lifespan),
      _RowData.score('India Score', b1.indiaSuitability?.score,
          b2.indiaSuitability?.score, higherBetter: true),
      _RowData.score('Friendly', b1.temperament?.friendlyScore,
          b2.temperament?.friendlyScore, higherBetter: true),
      _RowData.score('Trainable', b1.temperament?.trainableScore,
          b2.temperament?.trainableScore, higherBetter: true),
      _RowData.score('Energy', b1.temperament?.energyScore,
          b2.temperament?.energyScore, higherBetter: null),
      _RowData.score('Barking', b1.temperament?.barkingScore,
          b2.temperament?.barkingScore, higherBetter: false),
      _RowData.score('With Kids', b1.familyCompatibility?.withKids,
          b2.familyCompatibility?.withKids, higherBetter: true),
      _RowData.score('With Strangers', b1.familyCompatibility?.withStrangers,
          b2.familyCompatibility?.withStrangers, higherBetter: true),
      _RowData.text(
          'Apartment OK',
          b1.familyCompatibility?.goodForApartments == true ? 'Yes' : 'No',
          b2.familyCompatibility?.goodForApartments == true ? 'Yes' : 'No'),
      _RowData.text(
          'Shedding', b1.health?.sheddingLevel, b2.health?.sheddingLevel),
      _RowData.text('Grooming', b1.health?.groomingNeeds,
          b2.health?.groomingNeeds),
      _RowData.score('Exercise/day',
          b1.exercise?.dailyMinutes, b2.exercise?.dailyMinutes,
          higherBetter: null, unit: 'min'),
    ];
  }
}

class _RowData {
  final String label;
  final String? val1;
  final String? val2;
  final int? score1;
  final int? score2;
  final bool isScore;
  final bool? higherBetter; // null = neutral
  final String? unit;

  const _RowData({
    required this.label,
    this.val1,
    this.val2,
    this.score1,
    this.score2,
    required this.isScore,
    this.higherBetter,
    this.unit,
  });

  factory _RowData.text(String label, String? v1, String? v2) =>
      _RowData(label: label, val1: v1, val2: v2, isScore: false);

  factory _RowData.score(String label, int? s1, int? s2,
          {bool? higherBetter, String? unit}) =>
      _RowData(
          label: label,
          score1: s1,
          score2: s2,
          isScore: true,
          higherBetter: higherBetter,
          unit: unit);
}

class _CompareHeader extends StatelessWidget {
  final BreedInfo b1;
  final BreedInfo b2;
  const _CompareHeader({required this.b1, required this.b2});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 110),
        Expanded(child: _HeaderCell(breed: b1, isLeft: true)),
        const SizedBox(width: 6),
        Expanded(child: _HeaderCell(breed: b2, isLeft: false)),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final BreedInfo breed;
  final bool isLeft;
  const _HeaderCell({required this.breed, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLeft ? kBrown : kBrown2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(breed.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            breed.breed,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final _RowData row;
  const _CompareRow({required this.row});

  Color _cellColor(int? s1, int? s2, int? myScore, bool? higherBetter) {
    if (s1 == null || s2 == null || higherBetter == null) return Colors.white;
    final isBetter = higherBetter ? myScore! >= s2 : myScore! <= s2!;
    final isWorse = higherBetter ? myScore < s2 : myScore > s2;
    if (s1 == s2) return Colors.white;
    if (myScore == s1 && isBetter) return kGreenBg;
    if (myScore == s1 && isWorse) return kRedBg;
    if (myScore == s2 && isBetter) return kGreenBg;
    if (myScore == s2 && isWorse) return kRedBg;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(row.label,
                style: GoogleFonts.dmSans(fontSize: 12, color: kMuted)),
          ),
          if (row.isScore) ...[
            Expanded(
              child: _ScoreCell(
                score: row.score1,
                unit: row.unit,
                bg: _cellColor(
                    row.score1, row.score2, row.score1, row.higherBetter),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ScoreCell(
                score: row.score2,
                unit: row.unit,
                bg: _cellColor(
                    row.score1, row.score2, row.score2, row.higherBetter),
              ),
            ),
          ] else ...[
            Expanded(child: _TextCell(value: row.val1)),
            const SizedBox(width: 6),
            Expanded(child: _TextCell(value: row.val2)),
          ],
        ],
      ),
    );
  }
}

class _TextCell extends StatelessWidget {
  final String? value;
  const _TextCell({this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Text(
        value ?? '—',
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(fontSize: 12, color: kDark),
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  final int? score;
  final String? unit;
  final Color bg;
  const _ScoreCell({this.score, this.unit, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: score == null
          ? const Center(
              child: Text('—',
                  style: TextStyle(fontSize: 12, color: kMuted2)))
          : Column(
              children: [
                Text(
                  unit != null ? '$score $unit' : '$score',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kDark),
                ),
                if (unit == null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: score! / 100,
                      minHeight: 3,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation(kAmber),
                    ),
                  ),
              ],
            ),
    );
  }
}