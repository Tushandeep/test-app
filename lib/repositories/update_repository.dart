// import 'dart:convert';
// import 'dart:io';

// import 'package:http/http.dart' as http;
// import 'package:updat/utils/global_options.dart';

// class UpdateRepository {
//   const UpdateRepository();

//   Future<String> getBinaryUrl(String? version) async {
//     UpdatGlobalOptions.downloadReleaseHeaders = {
//       "Authorization": "Bearer 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",
//     };
//     final binaryUrl =
//         "https://github.com/Tushandeep/test-app/releases/download/$version/${Platform.operatingSystem}-$version.$_platformExtension";

//     return Future.value(binaryUrl);
//   }

//   Future<String?> getLatestVersion() async {
//     final Uri uri = Uri.parse("https://api.github.com/repos/Tushandeep/test-app/releases/latest");
//     final response = await http.get(uri);

//     final data = jsonDecode(response.body)['tag_name'];

//     return data;
//   }

//   Future<String?> getChangelog(String latestVersion, String appVersion) async {
//     final Uri uri = Uri.parse("https://api.github.com/repos/Tushandeep/test-app/releases/latest");
//     final response = await http.get(uri);

//     final releaseNotes = jsonDecode(response.body)['body'];

//     return releaseNotes;
//   }

//   String get _platformExtension {
//     switch (Platform.operatingSystem) {
//       case "windows":
//         return "exe";
//       case "macos":
//         return "dmg";
//       case "linux":
//         return "AppImage";
//       default:
//         return "zip";
//     }
//   }
// }
