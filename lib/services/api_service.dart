import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/breed_info.dart';
import '../models/detection_result.dart';

/// All network calls for PawID.
/// Instantiate once and share via Provider / InheritedWidget / get_it.
class PawIDApiService {
  String baseUrl;

  PawIDApiService({required this.baseUrl});

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode >= 500) {
      throw ApiException(
        'Server error (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Invalid JSON from server', statusCode: response.statusCode);
    }
  }

  // ─── 1. Health Check ───────────────────────────────────────────────────────

  /// Returns the raw health object. Throws [ApiException] on failure.
  Future<HealthStatus> checkHealth() async {
    try {
      final response =
          await http.get(_uri('/api/health')).timeout(const Duration(seconds: 8));
      final data = _decode(response);
      return HealthStatus.fromJson(data);
    } on SocketException {
      throw ApiException('Cannot reach server at $baseUrl');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Health check failed: $e');
    }
  }

  // ─── 2. Detect Breed (from File) ───────────────────────────────────────────

  Future<DetectionResult> detectBreed(File imageFile) async {
    try {
      final request =
          http.MultipartRequest('POST', _uri('/api/detect'));
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final data = _decode(response);
      return DetectionResult.fromJson(data);
    } on SocketException {
      throw ApiException('Cannot reach server at $baseUrl');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Detection failed: $e');
    }
  }

  // ─── 3. Detect Breed (from Bytes / Camera Snapshot) ───────────────────────

  Future<DetectionResult> detectBreedFromBytes(
      Uint8List bytes, String filename) async {
    try {
      final request =
          http.MultipartRequest('POST', _uri('/api/detect'));
      request.files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: filename),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final data = _decode(response);
      return DetectionResult.fromJson(data);
    } on SocketException {
      throw ApiException('Cannot reach server at $baseUrl');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Detection failed: $e');
    }
  }

  // ─── 4. Get Breed Info ─────────────────────────────────────────────────────

  Future<BreedInfo> getBreedInfo(String breedName) async {
    try {
      final encoded = Uri.encodeComponent(breedName);
      final response = await http
          .get(_uri('/api/breed/$encoded'))
          .timeout(const Duration(seconds: 10));
      final data = _decode(response);
      if (data['success'] != true) {
        throw ApiException(data['error'] ?? 'Breed not found');
      }
      return BreedInfo.fromJson(data['breed_info'] as Map<String, dynamic>);
    } on SocketException {
      throw ApiException('Cannot reach server at $baseUrl');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load breed info: $e');
    }
  }

  // ─── 5. List All Breeds ────────────────────────────────────────────────────

  Future<List<String>> getAllBreeds({String? query}) async {
    try {
      final path = query != null
          ? '/api/breeds?q=${Uri.encodeComponent(query)}'
          : '/api/breeds';
      final response =
          await http.get(_uri(path)).timeout(const Duration(seconds: 10));
      final data = _decode(response);
      return List<String>.from(data['breeds'] ?? []);
    } on SocketException {
      throw ApiException('Cannot reach server at $baseUrl');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to load breeds: $e');
    }
  }

  // ─── 6. Compare Two Breeds ─────────────────────────────────────────────────

  Future<CompareResult> compareBreeds(String breed1, String breed2) async {
    try {
      final b1 = Uri.encodeComponent(breed1);
      final b2 = Uri.encodeComponent(breed2);
      final response = await http
          .get(_uri('/api/compare?breed1=$b1&breed2=$b2'))
          .timeout(const Duration(seconds: 10));
      final data = _decode(response);
      if (data['success'] != true) {
        throw ApiException(data['error'] ?? 'Comparison failed');
      }
      return CompareResult(
        breed1: BreedInfo.fromJson(data['breed1'] as Map<String, dynamic>),
        breed2: BreedInfo.fromJson(data['breed2'] as Map<String, dynamic>),
      );
    } on SocketException {
      throw ApiException('Cannot reach server at $baseUrl');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Comparison failed: $e');
    }
  }

  // ─── 7. Analytics ──────────────────────────────────────────────────────────

  Future<AnalyticsData> getAnalytics() async {
    try {
      final response = await http
          .get(_uri('/api/analytics'))
          .timeout(const Duration(seconds: 10));
      final data = _decode(response);
      return AnalyticsData.fromJson(data);
    } on SocketException {
      throw ApiException('Cannot reach server at $baseUrl');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Analytics failed: $e');
    }
  }

  // ─── 8. PawBot Chat ────────────────────────────────────────────────────────

  /// [messages] is a list of {role: 'user'|'assistant', content: '...'}.
  /// Returns the assistant's reply text.
  Future<String> chat(
    List<Map<String, String>> messages, {
    String? currentBreed,
  }) async {
    try {
      final system = currentBreed != null
          ? 'Currently detected: "$currentBreed". You are PawBot, a dog breed expert. Answer concisely and helpfully for Indian dog owners.'
          : 'You are PawBot, a dog breed expert. Answer concisely and helpfully for Indian dog owners.';

      final response = await http
          .post(
            _uri('/api/chat'),
            headers: _jsonHeaders,
            body: json.encode({'messages': messages, 'system': system}),
          )
          .timeout(const Duration(seconds: 20));

      final data = _decode(response);
      final content = data['content'] as List?;
      if (content == null || content.isEmpty) {
        throw ApiException('Empty response from PawBot');
      }
      return content
          .whereType<Map>()
          .where((c) => c['type'] == 'text')
          .map((c) => c['text'] as String)
          .join('\n');
    } on SocketException {
      throw ApiException('Cannot reach server at $baseUrl');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Chat failed: $e');
    }
  }
}

// ─── Supporting response types ────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}

// ─────────────────────────────────────────────────────────────────────────────

class HealthStatus {
  final bool isRunning;
  final bool modelLoaded;
  final bool modelWorking;
  final int totalBreeds;
  final int totalModelClasses;
  final bool demoMode;

  const HealthStatus({
    required this.isRunning,
    required this.modelLoaded,
    required this.modelWorking,
    required this.totalBreeds,
    required this.totalModelClasses,
    required this.demoMode,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) => HealthStatus(
        isRunning: json['status'] == 'running',
        modelLoaded: json['model_loaded'] ?? false,
        modelWorking: json['model_working'] ?? false,
        totalBreeds: json['total_breeds_in_db'] ?? 0,
        totalModelClasses: json['total_model_classes'] ?? 0,
        demoMode: json['demo_mode'] ?? false,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class CompareResult {
  final BreedInfo breed1;
  final BreedInfo breed2;
  const CompareResult({required this.breed1, required this.breed2});
}

// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsData {
  final int totalDetections;
  final List<BreedCount> topBreeds;
  final List<DailyCount> dailyCounts;
  final Map<String, int> confidenceBuckets;
  final int totalBreedsInDb;

  const AnalyticsData({
    required this.totalDetections,
    required this.topBreeds,
    required this.dailyCounts,
    required this.confidenceBuckets,
    required this.totalBreedsInDb,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) => AnalyticsData(
        totalDetections: json['total_detections'] ?? 0,
        topBreeds: (json['top_breeds'] as List? ?? [])
            .map((b) => BreedCount.fromJson(b))
            .toList(),
        dailyCounts: (json['daily_counts'] as List? ?? [])
            .map((d) => DailyCount.fromJson(d))
            .toList(),
        confidenceBuckets: Map<String, int>.from(
          (json['confidence_buckets'] as Map? ?? {}).map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ),
        ),
        totalBreedsInDb: json['total_breeds_in_db'] ?? 0,
      );

  int get highConfidenceCount => confidenceBuckets['80-100'] ?? 0;
  int get uniqueBreedsDetected => topBreeds.length;
}

class BreedCount {
  final String breed;
  final int count;
  const BreedCount({required this.breed, required this.count});
  factory BreedCount.fromJson(Map<String, dynamic> json) =>
      BreedCount(breed: json['breed'] as String, count: (json['count'] as num).toInt());
}

class DailyCount {
  final String date;
  final int count;
  const DailyCount({required this.date, required this.count});
  factory DailyCount.fromJson(Map<String, dynamic> json) =>
      DailyCount(date: json['date'] as String, count: (json['count'] as num).toInt());
}