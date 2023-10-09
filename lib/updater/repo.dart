import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:test_app/updater/typedef.dart';
// import 'package:url_launcher/url_launcher.dart';

class UpdaterRepo {
  late dio.Dio _dio;
  late String _accessToken;

  UpdaterRepo() {
    _dio = dio.Dio();
    _accessToken = dotenv.get("COMPANY_ACCESS_TOKEN", fallback: "");
  }

  Future<(String, String)?> getLatestVersion({
    required String username,
    required String repoName,
  }) async {
    try {
      final Uri uri = Uri.parse("https://api.github.com/repos/$username/$repoName/releases/latest");
      final response = await _dio.getUri(
        uri,
        options: dio.Options(
          responseType: dio.ResponseType.json,
        ),
      );

      final data = response.data;

      if (data != null) {
        final String latestVersion = data['tag_name'] as String;
        final String releaseNotes = data['body'] as String;

        return (latestVersion, releaseNotes);
      }

      return null;
    } catch (err) {
      print(err.toString());
      rethrow;
    }
  }

  Future<void> downloadRelease(
    String savedPath,
    String url,
    String appName,
    AppUpdateDownloadProgress progress,
  ) async {
    try {
      await _dio.downloadUri(
        Uri.parse(url),
        savedPath,
        options: dio.Options(
          headers: {
            "Authorization": "Bearer $_accessToken",
          },
        ),
        onReceiveProgress: (count, total) => progress(count ~/ total),
      );
    } on dio.DioException catch (err) {
      throw Exception(
        'There was an issue downloading the file, please try again later.\n'
        'Code ${err.response?.statusCode}',
      );
    }
  }

  Future<void> openInstaller(String path, String appName) async {
    try {
      await _openUri(Uri(path: path, scheme: 'file'), appName);
    } catch (err) {
      throw Exception(
        'Installer does not exists, you have to download it first',
      );
    }
  }

  Future<void> _openUri(
    Uri uri,
    String appName,
  ) async {
    if (Platform.isWindows) {
      await Process.start(
        uri.toString(),
        ['/update', '/quiet'],
      );
    } else {
      return;
    }
  }

  // Future<void> _openUri(Uri uri, String appName) async {
  //   // if (await canLaunchUrl(uri)) {
  //   //   await launchUrl(uri, mode: LaunchMode.platformDefault);
  //   // } else {
  //   //   throw "Error";
  //   // }
  //   if (Platform.isMacOS) {
  //     await _installMacOSUpdate(uri, appName);

  //   } else {
  //     return;
  //   }
  //   // if (await canLaunchUrl(uri)) {
  //   //   await launchUrl(uri, mode: LaunchMode.platformDefault);
  //   // } else {
  //   //   throw "Error";
  //   // }
  // }

  // Future<void> _installMacOSUpdate(Uri uri, appName) async {
  //   // Mount the DMG file.
  //   final mountProcess = await Process.start('hdiutil', ['mount', uri.toString()]);
  //   await mountProcess.exitCode;

  //   // Get the path to the mounted DMG volume.
  //   final dmgVolumePath = await Process.run('hdiutil', ['info', uri.toString()]).then((processResult) {
  //     return processResult.stdout.split('\n')[0].trim();
  //   });

  //   // Install the Flutter macOS app update.
  //   final installProcess =
  //       await Process.start('sudo', ['installer', '-pkg', '$dmgVolumePath/$appName.pkg', '-target', '/']);
  //   await installProcess.exitCode;

  //   // Unmount the DMG file.
  //   final unmountProcess = await Process.start('hdiutil', ['unmount', dmgVolumePath]);
  //   await unmountProcess.exitCode;

  //   // Relaunch the app.
  //   final relaunchProcess = await Process.start('open', ['/Applications/$appName.app']);
  //   await relaunchProcess.exitCode;
  // }
}
