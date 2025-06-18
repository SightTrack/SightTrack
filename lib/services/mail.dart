// import 'package:sighttrack/barrel.dart';

// class Mail {
//   late String activitySupervisorEmail;
//   late String schoolSupervisorEmail;

//   Mail(this.activitySupervisorEmail, this.schoolSupervisorEmail);

//   Future<bool> sendVolunteerHoursRequest(
//     Map<String, dynamic> volunteerData,
//   ) async {
//     try {
//       final requestBody = {
//         'activitySupervisor': activitySupervisorEmail,
//         'schoolSupervisor': schoolSupervisorEmail,
//         'subject':
//             'Volunteer Hours Request - ${volunteerData['user']['name']} (${volunteerData['totalHours'].toStringAsFixed(2)} hours)',
//         'volunteerData': volunteerData,
//       };

//       final response =
//           await Amplify.API
//               .post(
//                 '/sendVolunteerHours',
//                 body: HttpPayload.json(requestBody),
//                 headers: {'Content-Type': 'application/json'},
//               )
//               .response;

//       final responseBody = json.decode(response.decodeBody());

//       if (response.statusCode == 200) {
//         Log.i(
//           'Volunteer hours request sent successfully: ${responseBody['message']}',
//         );
//         Log.i('Message ID: ${responseBody['messageId']}');
//         return true;
//       } else {
//         Log.e(
//           'Volunteer hours request failed: ${response.statusCode} - ${responseBody['error']}',
//         );
//         return false;
//       }
//     } on ApiException catch (e) {
//       Log.e('API call to /sendVolunteerHours failed (method: POST): $e');
//       return false;
//     } catch (e) {
//       Log.e('Unexpected error in volunteer hours request: $e');
//       return false;
//     }
//   }

//   // Keep the old method for backward compatibility if needed elsewhere
//   // Future<bool> sendEmail(String subject, String text) async {
//   //   try {
//   //     final requestBody = {
//   //       'activitySupervisor': activitySupervisorEmail,
//   //       'schoolSupervisor': schoolSupervisorEmail,
//   //       'subject': subject,
//   //       'emailBody': text,
//   //     };

//   //     final response =
//   //         await Amplify.API
//   //             .post(
//   //               '/sendVolunteerHours',
//   //               body: HttpPayload.json(requestBody),
//   //               headers: {'Content-Type': 'application/json'},
//   //             )
//   //             .response;

//   //     final responseBody = json.decode(response.decodeBody());

//   //     if (response.statusCode == 200) {
//   //       Log.i('Email sent successfully: ${responseBody['message']}');
//   //       Log.i('Message ID: ${responseBody['messageId']}');
//   //       return true;
//   //     } else {
//   //       Log.e(
//   //         'Email sending failed: ${response.statusCode} - ${responseBody['error']}',
//   //       );
//   //       return false;
//   //     }
//   //   } on ApiException catch (e) {
//   //     Log.e('API call to /sendVolunteerHours failed (method: POST): $e');
//   //     return false;
//   //   } catch (e) {
//   //     Log.e('Unexpected error in email sending: $e');
//   //     return false;
//   //   }
//   // }
// }
