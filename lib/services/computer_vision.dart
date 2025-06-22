import 'package:sighttrack/barrel.dart';
import 'package:http/http.dart' as http;

class ComputerVisionService {
  ComputerVisionService._();

  static const String _googleVisionApiUrl =
      'https://vision.googleapis.com/v1/images:annotate';

  static final String _apiKey = dotenv.env['GOOGLE_CLOUD'] ?? ' ';

  static Future<String> googleCloudVisionResponse({
    required String imagePath,
    int maxResults = 10,
  }) async {
    try {
      // Read and encode the image file to base64
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Prepare the request body for Google Cloud Vision API
      final requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': maxResults},
            ],
          },
        ],
      };

      // Make the HTTP POST request to Google Cloud Vision API
      final response = await http.post(
        Uri.parse('$_googleVisionApiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Return the raw JSON response string
      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Return error response as JSON string
        return jsonEncode({
          'error': {
            'code': response.statusCode,
            'message': 'Failed to analyze image',
            'details': response.body,
          },
        });
      }
    } catch (e) {
      // Return error as JSON string
      return jsonEncode({
        'error': {'code': -1, 'message': 'Exception occurred: $e'},
      });
    }
  }

  static Future<String> predictSpeciesWithGrok({
    required String visionApiResult,
  }) async {
    try {
      const String grokApiUrl = 'https://api.x.ai/v1/chat/completions';
      final String grokApiKey = dotenv.env['GROK'] ?? '';

      if (grokApiKey.isEmpty) {
        return jsonEncode({
          'error': {
            'code': -1,
            'message': 'GROK API key not found in environment variables',
          },
        });
      }

      // Prepare the request body for Grok API
      final requestBody = {
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful assistant machine that analyzes Google Cloud Vision API image results and returns 5 possible species.',
          },
          {
            'role': 'user',
            'content':
                'Analyze the following Google Cloud Vision API result and output exactly 5 possible species. Base your predictions solely on the data provided—do not guess or use external knowledge. Use the most accurate and relevant species names (common name followed by scientific name in parentheses) supported by the labels. Do not simply copy the label descriptions; synthesize the information to generate a reliable and meaningful prediction. Your response must be a single line with no extra text, formatted exactly as: species1 (scientific name), species2 (scientific name), species3 (scientific name), species4 (scientific name), species5 (scientific name). Each species must follow this format. Vision API result: $visionApiResult',
          },
        ],
        'model': 'grok-3-mini',
        'stream': false,
        'temperature': 0,
      };

      // Make the HTTP POST request to Grok API
      final response = await http.post(
        Uri.parse(grokApiUrl),
        headers: {
          'Authorization': 'Bearer $grokApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final grokResponse =
            responseData['choices'][0]['message']['content'] as String;

        // Log the LLM response (equivalent to console.log in JS)
        Log.i('LLM Response: $grokResponse');

        return grokResponse;
      } else {
        // Return error response as JSON string
        return jsonEncode({
          'error': {
            'code': response.statusCode,
            'message': 'Failed to call Grok API',
            'details': response.body,
          },
        });
      }
    } catch (e) {
      // Log error (equivalent to console.error in JS)
      Log.e('Error calling Grok API: $e');

      // Return error as JSON string
      return jsonEncode({
        'error': {'code': -1, 'message': 'Exception occurred: $e'},
      });
    }
  }

  static List<String> parseSpeciesFromLLMResponse(String llmResponse) {
    return llmResponse
        .trim()
        .split(RegExp(r',\s*'))
        .map((species) => species.trim())
        .where((species) => species.isNotEmpty)
        .toList();
  }
}
