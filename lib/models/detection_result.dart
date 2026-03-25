import 'breed_info.dart';

// ─── Prediction ───────────────────────────────────────────────────────────────

class Prediction {
  final int rank;
  final String breed;
  final double confidence;
  final String percentage;

  const Prediction({
    required this.rank,
    required this.breed,
    required this.confidence,
    required this.percentage,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
        rank: json['rank'] ?? 1,
        breed: json['breed'] ?? 'Unknown',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        percentage: json['percentage'] ?? '0%',
      );

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'breed': breed,
        'confidence': confidence,
        'percentage': percentage,
      };
}

// ─── DetectionResult ──────────────────────────────────────────────────────────

class DetectionResult {
  final bool success;
  final bool notADog;
  final bool demoMode;
  final bool lowConfidence;
  final String? error;
  final List<Prediction> predictions;
  final BreedInfo? breedInfo;
  final List<Prediction> alternatives;

  /// Raw base64-encoded PNG string from the server (no data-URI prefix).
  final String? gradcamBase64;

  const DetectionResult({
    required this.success,
    this.notADog = false,
    this.demoMode = false,
    this.lowConfidence = false,
    this.error,
    this.predictions = const [],
    this.breedInfo,
    this.alternatives = const [],
    this.gradcamBase64,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    final preds = (json['predictions'] as List? ?? [])
        .map((p) => Prediction.fromJson(p))
        .toList();

    final alts = (json['alternatives'] as List? ?? [])
        .map((a) => Prediction.fromJson(a))
        .toList();

    return DetectionResult(
      success: json['success'] ?? false,
      notADog: json['not_a_dog'] ?? false,
      demoMode: json['demo_mode'] ?? false,
      lowConfidence: json['low_confidence'] ?? false,
      error: json['error'],
      predictions: preds,
      breedInfo: json['breed_info'] != null
          ? BreedInfo.fromJson(json['breed_info'])
          : null,
      alternatives: alts,
      gradcamBase64: json['gradcam'],
    );
  }

  // Convenience: is likely a mixed breed?
  bool get isProbablyMixed {
    if (predictions.length < 2) return false;
    return predictions[0].confidence < 0.70 &&
        predictions[1].confidence > 0.15;
  }

  Prediction? get topPrediction =>
      predictions.isNotEmpty ? predictions.first : null;
}