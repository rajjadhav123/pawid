import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../config/constants.dart';
import '../main.dart';
import '../models/breed_info.dart';
import '../models/detection_result.dart';
import '../widgets/shared_widgets.dart';
import 'chat_screen.dart';
import 'compare_screen.dart';

class ResultScreen extends StatelessWidget {
  final DetectionResult result;
  final File? imageFile;

  const ResultScreen({super.key, required this.result, this.imageFile});

  @override
  Widget build(BuildContext context) {
    final breed = result.breedInfo;
    if (breed == null) {
      return Scaffold(
        body: Center(
          child: Text('No breed data',
              style: GoogleFonts.dmSans(color: kMuted)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kCream,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, breed),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Banners
                if (result.demoMode) _DemoBanner(),
                if (result.lowConfidence) _LowConfidenceBanner(),
                if (result.isProbablyMixed) _MixedBreedBanner(result),
                const SizedBox(height: 8),

                // Grad-CAM
                if (result.gradcamBase64 != null)
                  _GradCamSection(
                      gradcamB64: result.gradcamBase64!, imageFile: imageFile),

                // Trait tags
                if (breed.temperament?.traits.isNotEmpty == true)
                  _TraitTags(traits: breed.temperament!.traits),

                // Cards
                if (breed.indiaSuitability != null)
                  _IndiaSuitabilityCard(info: breed.indiaSuitability!),

                _BasicStatsCard(breed: breed),

                if (breed.temperament != null)
                  _TemperamentCard(info: breed.temperament!),

                if (breed.familyCompatibility != null)
                  _FamilyCard(info: breed.familyCompatibility!),

                if (breed.food != null) _DietCard(info: breed.food!),

                if (breed.temperature != null)
                  _ClimateCard(info: breed.temperature!),

                if (breed.exercise != null)
                  _ExerciseCard(info: breed.exercise!),

                if (breed.health != null) _HealthCard(info: breed.health!),

                if (breed.funFacts.isNotEmpty)
                  _FunFactsCard(facts: breed.funFacts),

                // Alternatives
                if (result.alternatives.isNotEmpty) ...[
                  const SectionHeader('Also Considered'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.alternatives
                        .map((a) => TagChip(
                              label:
                                  '${a.breed}  ${a.percentage}',
                              bg: kWarm,
                              fg: kBrown2,
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 24),

                // Action row
                _ActionRow(breed: breed, result: result),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SliverAppBar ────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(BuildContext context, BreedInfo breed) {
    final isIndian = kIndianBreeds.any(
        (b) => b.toLowerCase() == breed.breed.toLowerCase());

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: kBrown,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kDark, kBrown2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(breed.emoji,
                          style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    breed.breed,
                                    style: GoogleFonts.playfairDisplay(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (isIndian)
                                  const Text('🇮🇳',
                                      style: TextStyle(fontSize: 20)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (breed.origin != null) breed.origin!,
                                if (breed.group != null) breed.group!,
                                if (breed.size != null) breed.size!,
                              ].join(' · '),
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (result.topPrediction != null)
                    ConfidenceBadge(
                        confidence: result.topPrediction!.confidence,
                        label:
                            '${result.topPrediction!.percentage} confidence'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Banners ──────────────────────────────────────────────────────────────────

class _DemoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Banner(
        icon: Icons.science_outlined,
        text: 'Demo Mode — results are simulated',
        bg: kYellowBg,
        fg: kYellow,
      );
}

class _LowConfidenceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Banner(
        icon: Icons.warning_amber_rounded,
        text: 'Low Confidence — try a clearer, well-lit photo',
        bg: kYellowBg,
        fg: kYellow,
      );
}

class _MixedBreedBanner extends StatelessWidget {
  final DetectionResult result;
  const _MixedBreedBanner(this.result);

  @override
  Widget build(BuildContext context) {
    final names = result.predictions
        .take(3)
        .map((p) => '${p.breed} (${p.percentage})')
        .join(', ');
    return _Banner(
      icon: Icons.shuffle_rounded,
      text: 'Possible Mixed Breed: $names',
      bg: kBlueBg,
      fg: kBlueDark,
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  const _Banner({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.dmSans(fontSize: 12, color: fg)),
          ),
        ],
      ),
    );
  }
}

// ─── Grad-CAM ─────────────────────────────────────────────────────────────────

class _GradCamSection extends StatelessWidget {
  final String gradcamB64;
  final File? imageFile;

  const _GradCamSection({required this.gradcamB64, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'What the Model Saw',
      icon: Icons.visibility_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Highlighted regions indicate where the AI focused to identify the breed.',
            style: GoogleFonts.dmSans(fontSize: 12, color: kMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (imageFile != null)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(imageFile!,
                        height: 140, fit: BoxFit.cover),
                  ),
                ),
              if (imageFile != null) const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(gradcamB64),
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (imageFile != null)
                Text('Original',
                    style: GoogleFonts.spaceMono(fontSize: 9, color: kMuted)),
              Text('Grad-CAM Heatmap',
                  style: GoogleFonts.spaceMono(fontSize: 9, color: kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Trait Tags ───────────────────────────────────────────────────────────────

class _TraitTags extends StatelessWidget {
  final List<String> traits;
  const _TraitTags({required this.traits});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: traits
            .map((t) => TagChip(label: t, bg: kWarm, fg: kBrown2))
            .toList(),
      ),
    );
  }
}

// ─── India Suitability ────────────────────────────────────────────────────────

class _IndiaSuitabilityCard extends StatelessWidget {
  final IndiaSuitability info;
  const _IndiaSuitabilityCard({required this.info});

  Color get _color {
    final s = info.score ?? 0;
    if (s >= 70) return kGreen;
    if (s >= 45) return kAmber;
    return kRed;
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'India Suitability',
      icon: Icons.flag_rounded,
      iconColor: kAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🇮🇳', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '${info.score ?? '?'}/100',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (info.score ?? 0) / 100,
              minHeight: 10,
              backgroundColor: kWarm,
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
          if (info.notes != null) ...[
            const SizedBox(height: 8),
            Text(info.notes!,
                style: GoogleFonts.dmSans(fontSize: 12, color: kMuted)),
          ],
        ],
      ),
    );
  }
}

// ─── Basic Stats ──────────────────────────────────────────────────────────────

class _BasicStatsCard extends StatelessWidget {
  final BreedInfo breed;
  const _BasicStatsCard({required this.breed});

  @override
  Widget build(BuildContext context) {
    final stats = <String, String?>{
      'Lifespan': breed.lifespan,
      'Weight': breed.weightKg != null ? '${breed.weightKg} kg' : null,
      'Height': breed.heightCm != null ? '${breed.heightCm} cm' : null,
      'Coat': breed.coat,
      'Group': breed.group,
      'Origin': breed.origin,
    }.entries.where((e) => e.value != null).toList();

    return InfoCard(
      title: 'Basic Stats',
      icon: Icons.info_outline_rounded,
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        children: stats
            .map((e) => _StatChip(label: e.key, value: e.value!))
            .toList(),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.spaceMono(fontSize: 9, color: kMuted2,
                letterSpacing: 0.8)),
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
      ],
    );
  }
}

// ─── Temperament ──────────────────────────────────────────────────────────────

class _TemperamentCard extends StatelessWidget {
  final TemperamentInfo info;
  const _TemperamentCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Temperament',
      icon: Icons.psychology_outlined,
      child: Column(
        children: [
          if (info.friendlyScore != null)
            MeterBar(label: 'Friendly', value: info.friendlyScore!),
          if (info.trainableScore != null)
            MeterBar(label: 'Trainable', value: info.trainableScore!),
          if (info.energyScore != null)
            MeterBar(label: 'Energy', value: info.energyScore!),
          if (info.barkingScore != null)
            MeterBar(label: 'Barking', value: info.barkingScore!),
        ],
      ),
    );
  }
}

// ─── Family Compatibility ─────────────────────────────────────────────────────

class _FamilyCard extends StatelessWidget {
  final FamilyCompatibility info;
  const _FamilyCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Family Compatibility',
      icon: Icons.family_restroom_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.withKids != null)
            MeterBar(label: 'With Kids', value: info.withKids!),
          if (info.withStrangers != null)
            MeterBar(label: 'Strangers', value: info.withStrangers!),
          if (info.withOtherDogs != null)
            MeterBar(label: 'Other Dogs', value: info.withOtherDogs!),
          if (info.withCats != null)
            MeterBar(label: 'With Cats', value: info.withCats!),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (info.goodForApartments != null)
                TagChip(
                  label: info.goodForApartments!
                      ? '🏢 Apartment OK'
                      : '🏡 Needs Space',
                  bg: info.goodForApartments! ? kGreenBg : kRedBg,
                  fg: info.goodForApartments! ? kGreen : kRed,
                ),
              if (info.firstTimeOwner != null)
                TagChip(
                  label: info.firstTimeOwner!
                      ? '👍 First-time Friendly'
                      : '⚠️ Experienced Owner',
                  bg: info.firstTimeOwner! ? kGreenBg : kYellowBg,
                  fg: info.firstTimeOwner! ? kGreen : kYellow,
                ),
              if (info.guardDogRating != null)
                TagChip(
                  label: '🛡️ Guard: ${info.guardDogRating}',
                  bg: kBlueBg,
                  fg: kBlueDark,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Diet ────────────────────────────────────────────────────────────────────

class _DietCard extends StatelessWidget {
  final FoodInfo info;
  const _DietCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Diet & Nutrition',
      icon: Icons.restaurant_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.dietType != null) ...[
            TagChip(label: info.dietType!, bg: kGreenBg, fg: kGreen),
            const SizedBox(height: 10),
          ],
          if (info.mealsPerDay != null) ...[
            Text('${info.mealsPerDay} meals/day',
                style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
            const SizedBox(height: 8),
          ],
          if (info.recommended.isNotEmpty) ...[
            Text('Recommended',
                style: GoogleFonts.spaceMono(
                    fontSize: 9, color: kMuted2, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: info.recommended
                  .map((f) => TagChip(label: '✓ $f', bg: kGreenBg, fg: kGreen))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (info.avoid.isNotEmpty) ...[
            Text('Avoid',
                style: GoogleFonts.spaceMono(
                    fontSize: 9, color: kMuted2, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: info.avoid
                  .map((f) => TagChip(label: '✗ $f', bg: kRedBg, fg: kRed))
                  .toList(),
            ),
          ],
          if (info.specialNotes != null) ...[
            const SizedBox(height: 8),
            Text(info.specialNotes!,
                style: GoogleFonts.dmSans(fontSize: 12, color: kMuted)),
          ],
        ],
      ),
    );
  }
}

// ─── Climate ──────────────────────────────────────────────────────────────────

class _ClimateCard extends StatelessWidget {
  final TemperatureInfo info;
  const _ClimateCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Climate & Temperature',
      icon: Icons.thermostat_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.idealCelsius != null) ...[
            Row(children: [
              const Text('🌡️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text('Ideal: ${info.idealCelsius}°C',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
            ]),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (info.climate != null)
                TagChip(label: '☁️ ${info.climate}', bg: kBlueBg, fg: kBlueDark),
              if (info.heatTolerance != null)
                TagChip(label: '☀️ Heat: ${info.heatTolerance}',
                    bg: const Color(0xFFFFF3E0),
                    fg: const Color(0xFFE65100)),
              if (info.coldTolerance != null)
                TagChip(label: '❄️ Cold: ${info.coldTolerance}',
                    bg: kBlueBg, fg: kBlueDark),
            ],
          ),
          if (info.notes != null) ...[
            const SizedBox(height: 8),
            Text(info.notes!,
                style: GoogleFonts.dmSans(fontSize: 12, color: kMuted)),
          ],
        ],
      ),
    );
  }
}

// ─── Exercise ─────────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final ExerciseInfo info;
  const _ExerciseCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Exercise Needs',
      icon: Icons.directions_run_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.dailyMinutes != null)
            Row(children: [
              const Text('⏱️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('${info.dailyMinutes} min / day',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 20, fontWeight: FontWeight.w700, color: kDark)),
            ]),
          if (info.intensity != null) ...[
            const SizedBox(height: 6),
            TagChip(label: '${info.intensity} Intensity',
                bg: kWarm, fg: kBrown2),
          ],
          if (info.activities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: info.activities
                  .map((a) => TagChip(label: a, bg: kGreenBg, fg: kGreen))
                  .toList(),
            ),
          ],
          if (info.notes != null) ...[
            const SizedBox(height: 8),
            Text(info.notes!,
                style: GoogleFonts.dmSans(fontSize: 12, color: kMuted)),
          ],
        ],
      ),
    );
  }
}

// ─── Health ───────────────────────────────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  final HealthInfo info;
  const _HealthCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Health & Grooming',
      icon: Icons.health_and_safety_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (info.groomingNeeds != null)
                TagChip(label: '✂️ Grooming: ${info.groomingNeeds}',
                    bg: kWarm, fg: kBrown2),
              if (info.sheddingLevel != null)
                TagChip(label: '🐾 Shedding: ${info.sheddingLevel}',
                    bg: kWarm, fg: kBrown2),
              if (info.hypoallergenic != null)
                TagChip(
                  label: info.hypoallergenic!
                      ? '✅ Hypoallergenic'
                      : '❌ Not Hypoallergenic',
                  bg: info.hypoallergenic! ? kGreenBg : kRedBg,
                  fg: info.hypoallergenic! ? kGreen : kRed,
                ),
            ],
          ),
          if (info.commonIssues.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Common Health Issues',
                style: GoogleFonts.spaceMono(
                    fontSize: 9, color: kMuted2, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: info.commonIssues
                  .map((i) => TagChip(label: i, bg: kRedBg, fg: kRed))
                  .toList(),
            ),
          ],
          if (info.lifespanNote != null) ...[
            const SizedBox(height: 8),
            Text(info.lifespanNote!,
                style: GoogleFonts.dmSans(fontSize: 12, color: kMuted)),
          ],
        ],
      ),
    );
  }
}

// ─── Fun Facts ────────────────────────────────────────────────────────────────

class _FunFactsCard extends StatelessWidget {
  final List<String> facts;
  const _FunFactsCard({required this.facts});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Fun Facts',
      icon: Icons.auto_awesome_rounded,
      iconColor: kAmber,
      child: Column(
        children: facts
            .asMap()
            .entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: kAmber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.value,
                          style:
                              GoogleFonts.dmSans(fontSize: 13, color: kDark)),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Action Row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final BreedInfo breed;
  final DetectionResult result;

  const _ActionRow({required this.breed, required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Btn(
          icon: Icons.share_rounded,
          label: 'Share',
          onTap: () => Share.share(
              '${breed.emoji} I identified a ${breed.breed} using PawID! '
              'India suitability: ${breed.indiaSuitability?.score ?? "N/A"}/100'),
        ),
        const SizedBox(width: 8),
        _Btn(
          icon: Icons.compare_arrows_rounded,
          label: 'Compare',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompareScreen(prefillBreed: breed.breed),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Text('🤖', style: TextStyle(fontSize: 16)),
            label: Text('Ask PawBot',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(currentBreed: breed.breed),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Btn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8D8C4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kAmber, size: 20),
            const SizedBox(height: 3),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w500, color: kBrown)),
          ],
        ),
      ),
    );
  }
}