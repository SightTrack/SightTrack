import 'package:sighttrack/barrel.dart';
import 'package:http/http.dart' as http;

class Mail {
  late String apiKey;
  late String from, to;

  Mail(this.from, this.to) {
    try {
      final mailgunKey = dotenv.env['MAILGUN'];
      if (mailgunKey == null || mailgunKey.isEmpty) {
        throw Exception('MAILGUN environment variable not found or empty');
      }
      apiKey = mailgunKey;
    } catch (e) {
      Log.e('Error loading dotenv: $e');
      rethrow;
    }
  }

  Future<http.Response?> sendEmail(String subject, String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.mailgun.net/v3/mail.sighttrack.org/messages'),
        headers: {
          'Authorization': 'Basic ${base64.encode(utf8.encode('api:$apiKey'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'from': from, 'to': to, 'subject': subject, 'text': text},
      );
      Log.i('Email sent: ${response.statusCode}');
      return response;
    } catch (e) {
      Log.e('Error sending email: $e');
      return null;
    }
  }
}
