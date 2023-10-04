import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:updat/updat_window_manager.dart';
import 'package:http/http.dart' as http;

late PackageInfo _packageInfo;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _packageInfo = await PackageInfo.fromPlatform();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return UpdatWindowManager(
      appName: _packageInfo.appName,
      currentVersion: _packageInfo.version,
      getBinaryUrl: (version) {
        final binaryUrl =
            "https://api.github.com/repos/Tushandeep/test-app/releases/download/$version/${Platform.operatingSystem}-$version.$platformExtension";

        return Future.value(binaryUrl);
      },
      getLatestVersion: () async {
        final Uri uri = Uri.parse("https://api.github.com/repos/Tushandeep/test-app/releases/latest");
        final response = await http.get(uri);

        return jsonDecode(response.body)['tag_name'];
      },
      getChangelog: (_, __) async {
        final Uri uri = Uri.parse("https://api.github.com/repos/Tushandeep/test-app/releases/latest");
        final response = await http.get(uri);

        return jsonDecode(response.body)['body'];
      },
      callback: (status) => print(status),
      closeOnInstall: true,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Version: ${_packageInfo.version}",
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "App Name: ${_packageInfo.appName}",
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String get platformExtension {
  switch (Platform.operatingSystem) {
    case "windows":
      return "exe";
    case "macos":
      return "dmg";
    case "linux":
      return "AppImage";
    default:
      return "zip";
  }
}
