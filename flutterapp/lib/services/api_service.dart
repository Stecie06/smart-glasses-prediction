import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  
  // For local testing, use: 'http://localhost:8000'
  // For production, use your deployed URL from Render
  
  static const Duration timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> predictDemand({
    required int cognition,
    required int communication,
    required int hearing,
    required int mobility,
    required int selfCare,
    required int vision,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/predict');
      
      final requestBody = {
        'cognition': cognition,
        'communication': communication,
        'hearing': hearing,
        'mobility': mobility,
        'self_care': selfCare,
        'vision': vision,
      };

      print('Making API request to: $uri');
      print('Request body: $requestBody');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else if (response.statusCode == 422) {
        // Validation error
        final errorData = jsonDecode(response.body);
        throw Exception('Validation Error: ${errorData['details'] ?? 'Invalid input values'}');
      } else if (response.statusCode == 500) {
        throw Exception('Server Error: The prediction service is currently unavailable');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout. Please check your internet connection and try again.');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Network error. Please check your internet connection.');
      } else if (e.toString().contains('FormatException')) {
        throw Exception('Invalid response from server. Please try again.');
      } else {
        throw Exception('Prediction failed: ${e.toString()}');
      }
    }
  }

  Future<Map<String, dynamic>> checkApiHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      
      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Health check failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Health check failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final uri = Uri.parse('$baseUrl/model-info');
      
      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get model info: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get model info: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> predictBatch(
      List<Map<String, int>> requests) async {
    try {
      final uri = Uri.parse('$baseUrl/predict-batch');
      
      final requestBody = requests.map((request) => {
        'cognition': request['cognition'],
        'communication': request['communication'],
        'hearing': request['hearing'],
        'mobility': request['mobility'],
        'self_care': request['self_care'],
        'vision': request['vision'],
      }).toList();

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['batch_results']);
      } else {
        throw Exception('Batch prediction failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Batch prediction failed: ${e.toString()}');
    }
  }

  // Helper method to validate input values
  static bool isValidInput(int value) {
    return value == 0 || value == 1;
  }

  // Helper method to validate all inputs
  static String? validateInputs({
    required int cognition,
    required int communication,
    required int hearing,
    required int mobility,
    required int selfCare,
    required int vision,
  }) {
    final inputs = {
      'cognition': cognition,
      'communication': communication,
      'hearing': hearing,
      'mobility': mobility,
      'self_care': selfCare,
      'vision': vision,
    };

    for (final entry in inputs.entries) {
      if (!isValidInput(entry.value)) {
        return 'Invalid value for ${entry.key}: must be 0 (No) or 1 (Yes)';
      }
    }

    return null; // All inputs are valid
  }

  // Helper method to convert boolean to API format
  static int boolToApiValue(bool value) {
    return value ? 1 : 0;
  }

  // Helper method to get demand level description
  static String getDemandDescription(int demandScore) {
    switch (demandScore) {
      case 1:
        return 'Low demand - Market shows limited need for smart glasses';
      case 2:
        return 'Medium demand - Moderate market potential for smart glasses';
      case 3:
        return 'High demand - Strong market opportunity for smart glasses';
      default:
        return 'Unknown demand level';
    }
  }

  // Helper method to get confidence level description
  static String getConfidenceDescription(double confidence) {
    if (confidence >= 0.9) {
      return 'Very High Confidence';
    } else if (confidence >= 0.8) {
      return 'High Confidence';
    } else if (confidence >= 0.7) {
      return 'Medium Confidence';
    } else {
      return 'Low Confidence';
    }
  }
}