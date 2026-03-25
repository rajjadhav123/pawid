// ─── breed_info.dart ─────────────────────────────────────────────────────────

class BreedInfo {
  final String breed;
  final String? origin;
  final String? group;
  final String? size;
  final String? weightKg;
  final String? heightCm;
  final String? lifespan;
  final String? coat;
  final String emoji;
  final String? description;
  final TemperatureInfo? temperature;
  final FoodInfo? food;
  final TemperamentInfo? temperament;
  final FamilyCompatibility? familyCompatibility;
  final ExerciseInfo? exercise;
  final HealthInfo? health;
  final IndiaSuitability? indiaSuitability;
  final List<String> funFacts;

  const BreedInfo({
    required this.breed,
    this.origin,
    this.group,
    this.size,
    this.weightKg,
    this.heightCm,
    this.lifespan,
    this.coat,
    this.emoji = '🐕',
    this.description,
    this.temperature,
    this.food,
    this.temperament,
    this.familyCompatibility,
    this.exercise,
    this.health,
    this.indiaSuitability,
    this.funFacts = const [],
  });

  factory BreedInfo.fromJson(Map<String, dynamic> json) {
    return BreedInfo(
      breed: json['breed'] ?? json['name'] ?? 'Unknown',
      origin: json['origin'],
      group: json['group'],
      size: json['size'],
      weightKg: json['weight_kg']?.toString(),
      heightCm: json['height_cm']?.toString(),
      lifespan: json['lifespan'] ?? json['stats']?['lifespan'],
      coat: json['coat'],
      emoji: json['emoji'] ?? '🐕',
      description: json['description'],
      temperature: json['temperature'] != null
          ? TemperatureInfo.fromJson(json['temperature'])
          : null,
      food: json['food'] != null ? FoodInfo.fromJson(json['food']) : null,
      temperament: json['temperament'] != null
          ? TemperamentInfo.fromJson(json['temperament'])
          : null,
      familyCompatibility: json['family_compatibility'] != null
          ? FamilyCompatibility.fromJson(json['family_compatibility'])
          : null,
      exercise: json['exercise'] != null
          ? ExerciseInfo.fromJson(json['exercise'])
          : null,
      health: json['health'] != null ? HealthInfo.fromJson(json['health']) : null,
      indiaSuitability: json['india_suitability'] != null
          ? IndiaSuitability.fromJson(json['india_suitability'])
          : null,
      funFacts: List<String>.from(json['fun_facts'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'breed': breed,
        'origin': origin,
        'group': group,
        'size': size,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'lifespan': lifespan,
        'coat': coat,
        'emoji': emoji,
        'description': description,
        'temperature': temperature?.toJson(),
        'food': food?.toJson(),
        'temperament': temperament?.toJson(),
        'family_compatibility': familyCompatibility?.toJson(),
        'exercise': exercise?.toJson(),
        'health': health?.toJson(),
        'india_suitability': indiaSuitability?.toJson(),
        'fun_facts': funFacts,
      };
}

// ─── Temperature ──────────────────────────────────────────────────────────────

class TemperatureInfo {
  final String? idealCelsius;
  final String? climate;
  final String? heatTolerance;
  final String? coldTolerance;
  final String? notes;

  const TemperatureInfo({
    this.idealCelsius,
    this.climate,
    this.heatTolerance,
    this.coldTolerance,
    this.notes,
  });

  factory TemperatureInfo.fromJson(Map<String, dynamic> json) => TemperatureInfo(
        idealCelsius: json['ideal_celsius']?.toString(),
        climate: json['climate'],
        heatTolerance: json['heat_tolerance'],
        coldTolerance: json['cold_tolerance'],
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'ideal_celsius': idealCelsius,
        'climate': climate,
        'heat_tolerance': heatTolerance,
        'cold_tolerance': coldTolerance,
        'notes': notes,
      };
}

// ─── Food ─────────────────────────────────────────────────────────────────────

class FoodInfo {
  final String? dietType;
  final List<String> recommended;
  final List<String> avoid;
  final int? mealsPerDay;
  final String? specialNotes;

  const FoodInfo({
    this.dietType,
    this.recommended = const [],
    this.avoid = const [],
    this.mealsPerDay,
    this.specialNotes,
  });

  factory FoodInfo.fromJson(Map<String, dynamic> json) => FoodInfo(
        dietType: json['diet_type'],
        recommended: List<String>.from(json['recommended'] ?? []),
        avoid: List<String>.from(json['avoid'] ?? []),
        mealsPerDay: json['meals_per_day'],
        specialNotes: json['special_notes'],
      );

  Map<String, dynamic> toJson() => {
        'diet_type': dietType,
        'recommended': recommended,
        'avoid': avoid,
        'meals_per_day': mealsPerDay,
        'special_notes': specialNotes,
      };
}

// ─── Temperament ──────────────────────────────────────────────────────────────

class TemperamentInfo {
  final int? friendlyScore;
  final int? trainableScore;
  final int? energyScore;
  final int? barkingScore;
  final List<String> traits;

  const TemperamentInfo({
    this.friendlyScore,
    this.trainableScore,
    this.energyScore,
    this.barkingScore,
    this.traits = const [],
  });

  factory TemperamentInfo.fromJson(Map<String, dynamic> json) => TemperamentInfo(
        friendlyScore: json['friendly_score'],
        trainableScore: json['trainable_score'],
        energyScore: json['energy_score'],
        barkingScore: json['barking_score'],
        traits: List<String>.from(json['traits'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'friendly_score': friendlyScore,
        'trainable_score': trainableScore,
        'energy_score': energyScore,
        'barking_score': barkingScore,
        'traits': traits,
      };
}

// ─── Family Compatibility ─────────────────────────────────────────────────────

class FamilyCompatibility {
  final int? withKids;
  final int? withStrangers;
  final int? withOtherDogs;
  final int? withCats;
  final bool? goodForApartments;
  final String? guardDogRating;
  final bool? firstTimeOwner;

  const FamilyCompatibility({
    this.withKids,
    this.withStrangers,
    this.withOtherDogs,
    this.withCats,
    this.goodForApartments,
    this.guardDogRating,
    this.firstTimeOwner,
  });

  factory FamilyCompatibility.fromJson(Map<String, dynamic> json) =>
      FamilyCompatibility(
        withKids: json['with_kids'],
        withStrangers: json['with_strangers'],
        withOtherDogs: json['with_other_dogs'],
        withCats: json['with_cats'],
        goodForApartments: json['good_for_apartments'],
        guardDogRating: json['guard_dog_rating'],
        firstTimeOwner: json['first_time_owner'],
      );

  Map<String, dynamic> toJson() => {
        'with_kids': withKids,
        'with_strangers': withStrangers,
        'with_other_dogs': withOtherDogs,
        'with_cats': withCats,
        'good_for_apartments': goodForApartments,
        'guard_dog_rating': guardDogRating,
        'first_time_owner': firstTimeOwner,
      };
}

// ─── Exercise ─────────────────────────────────────────────────────────────────

class ExerciseInfo {
  final int? dailyMinutes;
  final String? intensity;
  final List<String> activities;
  final String? notes;

  const ExerciseInfo({
    this.dailyMinutes,
    this.intensity,
    this.activities = const [],
    this.notes,
  });

  factory ExerciseInfo.fromJson(Map<String, dynamic> json) => ExerciseInfo(
        dailyMinutes: json['daily_minutes'],
        intensity: json['intensity'],
        activities: List<String>.from(json['activities'] ?? []),
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'daily_minutes': dailyMinutes,
        'intensity': intensity,
        'activities': activities,
        'notes': notes,
      };
}

// ─── Health ───────────────────────────────────────────────────────────────────

class HealthInfo {
  final List<String> commonIssues;
  final String? groomingNeeds;
  final String? sheddingLevel;
  final bool? hypoallergenic;
  final String? lifespanNote;

  const HealthInfo({
    this.commonIssues = const [],
    this.groomingNeeds,
    this.sheddingLevel,
    this.hypoallergenic,
    this.lifespanNote,
  });

  factory HealthInfo.fromJson(Map<String, dynamic> json) => HealthInfo(
        commonIssues: List<String>.from(json['common_issues'] ?? []),
        groomingNeeds: json['grooming_needs'],
        sheddingLevel: json['shedding_level'],
        hypoallergenic: json['hypoallergenic'],
        lifespanNote: json['lifespan_note'],
      );

  Map<String, dynamic> toJson() => {
        'common_issues': commonIssues,
        'grooming_needs': groomingNeeds,
        'shedding_level': sheddingLevel,
        'hypoallergenic': hypoallergenic,
        'lifespan_note': lifespanNote,
      };
}

// ─── India Suitability ────────────────────────────────────────────────────────

class IndiaSuitability {
  final int? score;
  final String? notes;

  const IndiaSuitability({this.score, this.notes});

  factory IndiaSuitability.fromJson(Map<String, dynamic> json) =>
      IndiaSuitability(
        score: json['score'],
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {'score': score, 'notes': notes};
}