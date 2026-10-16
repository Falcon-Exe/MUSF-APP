import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

class GoogleSheetsResult {
  final String eventName;
  final String category;
  final String? firstPlaceId;
  final String? firstPlaceName;
  final String? secondPlaceId;
  final String? secondPlaceName;
  final String? thirdPlaceId;
  final String? thirdPlaceName;

  GoogleSheetsResult({
    required this.eventName,
    this.category = 'On-Stage',
    this.firstPlaceId,
    this.firstPlaceName,
    this.secondPlaceId,
    this.secondPlaceName,
    this.thirdPlaceId,
    this.thirdPlaceName,
  });
}

class GoogleSheetsHelper {
  // Simple in-memory cache
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Converts a standard Google Sheet URL to a CSV export URL.
  static String? _getExportUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.path.toLowerCase().endsWith('.csv')) {
      return url;
    }
    if (url.contains('format=csv') || url.contains('output=csv')) {
      return url;
    }

    final RegExp regExp = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)');
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final String? id = match.group(1);
      final gid = uri?.queryParameters['gid'];
      final gidPart = gid == null ? '' : '&gid=$gid';
      return 'https://docs.google.com/spreadsheets/d/$id/export?format=csv$gidPart';
    }
    return null;
  }

  /// Fetches and parses Google Sheets data for a given URL.
  static Future<List<GoogleSheetsResult>> fetchResults(String url) async {
    // Check cache first
    if (_cache.containsKey(url)) {
      final entry = _cache[url]!;
      if (DateTime.now().difference(entry.timestamp) < _cacheDuration) {
        return entry.data;
      }
      _cache.remove(url);
    }

    final exportUrl = _getExportUrl(url);
    if (exportUrl == null) {
      throw Exception("Paste a public Google Sheet link or direct CSV link.");
    }

    final response = await http.get(Uri.parse(exportUrl));
    if (response.statusCode != 200) {
      throw Exception("Failed to fetch sheet data: ${response.statusCode}");
    }

    final String csvData = response.body;

    // Offload parsing to a background isolate (compute)
    final results = await compute(_parseCsvData, csvData);

    // Save to cache
    _cache[url] = _CacheEntry(results, DateTime.now());

    return results;
  }

  /// Top-level or static function for Isolate parsing
  static List<GoogleSheetsResult> _parseCsvData(String csv) {
    final List<List<dynamic>> rows = const CsvToListConverter().convert(csv);
    if (rows.isEmpty) return [];

    final header = rows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList();
    final int eventIdx = header.indexOf('event');
    final int prizeIdx = header.indexOf('prize');
    final int nameIdx = header.indexOf('name');

    if (eventIdx == -1 || prizeIdx == -1 || nameIdx == -1) {
      throw Exception(
        "Required columns (Event, Prize, Name) not found in sheet",
      );
    }

    final Map<String, List<Map<String, String>>> groupedResults = {};
    final int categoryIdx = _firstHeaderIndex(header, [
      'category',
      'type',
      'stage',
    ]);
    final int idIdx = _firstHeaderIndex(header, [
      'studentid',
      'student id',
      'student_id',
      'id',
      'admission no',
      'admission',
      'cic id',
    ]);

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final requiredMaxIndex = [eventIdx, prizeIdx, nameIdx]
          .reduce((value, element) => value > element ? value : element);
      if (row.length <= requiredMaxIndex) continue;

      final event = row[eventIdx].toString().trim();
      final prize = row[prizeIdx].toString().trim().toLowerCase();
      final name = row[nameIdx].toString().trim();
      final category = categoryIdx >= 0 && row.length > categoryIdx
          ? row[categoryIdx].toString().trim()
          : 'On-Stage';
      final id = idIdx >= 0 && row.length > idIdx
          ? row[idIdx].toString().trim()
          : '';

      if (event.isEmpty) continue;

      if (!groupedResults.containsKey(event)) {
        groupedResults[event] = [];
      }
      groupedResults[event]!.add({
        'prize': prize,
        'name': name,
        'id': id,
        'category': category,
      });
    }

    final List<GoogleSheetsResult> results = [];
    groupedResults.forEach((event, participants) {
      String? first;
      String? firstId;
      String? second;
      String? secondId;
      String? third;
      String? thirdId;
      String category = 'On-Stage';

      for (var p in participants) {
        final prize = p['prize'];
        final name = p['name'];
        final id = p['id'];
        category = p['category']?.isNotEmpty == true ? p['category']! : category;

        if (_isFirstPrize(prize)) {
          first = name;
          firstId = id;
        } else if (_isSecondPrize(prize)) {
          second = name;
          secondId = id;
        } else if (_isThirdPrize(prize)) {
          third = name;
          thirdId = id;
        }
      }

      results.add(
        GoogleSheetsResult(
          eventName: event,
          category: category,
          firstPlaceId: firstId,
          firstPlaceName: first,
          secondPlaceId: secondId,
          secondPlaceName: second,
          thirdPlaceId: thirdId,
          thirdPlaceName: third,
        ),
      );
    });

    return results;
  }

  static int _firstHeaderIndex(List<String> header, List<String> names) {
    for (final name in names) {
      final index = header.indexOf(name);
      if (index >= 0) return index;
    }
    return -1;
  }

  static bool _isFirstPrize(String? prize) {
    final value = (prize ?? '').toLowerCase();
    return value == 'first' || value == '1' || value == '1st';
  }

  static bool _isSecondPrize(String? prize) {
    final value = (prize ?? '').toLowerCase();
    return value == 'second' || value == '2' || value == '2nd';
  }

  static bool _isThirdPrize(String? prize) {
    final value = (prize ?? '').toLowerCase();
    return value == 'third' || value == '3' || value == '3rd';
  }
}

class _CacheEntry {
  final List<GoogleSheetsResult> data;
  final DateTime timestamp;
  _CacheEntry(this.data, this.timestamp);
}
