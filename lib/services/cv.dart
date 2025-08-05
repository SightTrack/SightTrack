import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:sighttrack/barrel.dart';

class ComputerVisionInstance {
  String _provider = 'openai';
  String _apiKey = dotenv.env['OPENAI'] ?? '';
  // String _apiUrl = 'https://api.x.ai/v1/chat/completions';
  String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> extractImageCharacteristics(String imagepath) async {
    try {
      // Read and encode the image
      final imageFile = File(imagepath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final requestBody = {
        'messages': [
          {
            'role': 'system',
            'content':
                'You are SightTrack\'s Image Analysis Assistant, responsible for extracting defining visual features from a given image. Your output will be processed by a separate assistant that identifies potential species based solely on your description, without seeing the image itself.',
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': await rootBundle.loadString(
                  'assets/prompts/image_processing.txt',
                ),
              },
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
            ],
          },
        ],
        'model': _provider == 'grok' ? 'grok-4-0709' : 'gpt-4.1-mini',
        'stream': false,
        'temperature': 0,
      };

      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final modelResponse =
            responseData['choices'][0]['message']['content'] as String;

        Log.i('LLM Response: $modelResponse');

        return modelResponse;
      } else {
        Log.e(
          'Failed to call model API: ${response.statusCode} - ${response.body}',
        );

        return 'NONE';
      }
    } catch (e) {
      Log.e('Error calling model API: $e');

      return 'NONE';
    }
  }

  Future<String> identifyImageFromCharacteristics(
    String characteristics,
  ) async {
    try {
      final requestBody = {
        'messages': [
          {
            'role': 'system',
            'content':
                'You are SightTrack\’s Species Identifier. Your task is to receive a list of key characteristics describing an organism. Based solely on these traits, you must return a list of approximately 5 possible species, using their scientific names.',
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    '${await rootBundle.loadString('assets/prompts/image_identifier.txt')}\n$characteristics',
              },
            ],
          },
        ],
        'model': _provider == 'grok' ? 'grok-4-0709' : 'gpt-4.1-mini',
        'stream': false,
        'temperature': 0,
      };

      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final modelResponse =
            responseData['choices'][0]['message']['content'] as String;

        Log.i('LLM Response: $modelResponse');

        return modelResponse;
      } else {
        Log.e(
          'Failed to call model API: ${response.statusCode} - ${response.body}',
        );

        return 'NONE';
      }
    } catch (e) {
      Log.e('Error calling model API: $e');

      return 'NONE';
    }
  }

  Future<List<String>> startImageIdentification(String imagepath) async {
    String characteristics = await extractImageCharacteristics(imagepath);
    if (characteristics == 'NONE') {
      Log.e('Failed to extract characteristics from image.');
      return [];
    }
    String identifiedSpecies = await identifyImageFromCharacteristics(
      characteristics,
    );
    if (identifiedSpecies == 'NONE') {
      Log.e('Failed to identify species from characteristics.');
      return [];
    }

    // Parse the string format [species1, species2, species3] into a List<String>
    try {
      // Remove the brackets and split by commas
      String cleanedString = identifiedSpecies.trim();
      if (cleanedString.startsWith('[') && cleanedString.endsWith(']')) {
        cleanedString = cleanedString.substring(1, cleanedString.length - 1);
      }

      List<String> speciesList =
          cleanedString
              .split(',')
              .map((species) => species.trim())
              .where((species) => species.isNotEmpty)
              .toList();

      Log.i('Parsed species list: $speciesList');
      return speciesList;
    } catch (e) {
      Log.e('Error parsing species list: $e');
      return [];
    }
  }

  Future<String> startManualAutocorrection(String input) async {
    try {
      final requestBody = {
        'messages': [
          {
            'role': 'system',
            'content':
                'You are SightTrack\’s Species Autocorrector. Your task is to receive a string related to a species from a user, which may be mispelled or contain errors, and return the corrected version.',
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    '${await rootBundle.loadString('assets/prompts/manual_species_autocorrection.txt')}\n$input',
              },
            ],
          },
        ],
        'model': _provider == 'grok' ? 'grok-4-0709' : 'gpt-4.1-mini',
        'stream': false,
        'temperature': 0,
      };

      // Make the HTTP POST request
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final modelResponse =
            responseData['choices'][0]['message']['content'] as String;

        Log.i('LLM Response: $modelResponse');

        return modelResponse;
      } else {
        Log.e(
          'Failed to call model API: ${response.statusCode} - ${response.body}',
        );

        return 'NONE';
      }
    } catch (e) {
      Log.e('Error calling model API: $e');

      return 'NONE';
    }
  }
}
