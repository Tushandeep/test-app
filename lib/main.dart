import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:updat/updat_window_manager.dart';
import 'package:http/http.dart' as http;

late PackageInfo _packageInfo;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _packageInfo = await PackageInfo.fromPlatform();

  ErrorWidget.builder = (error) => Text(error.exception.toString());

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppController.instance;
    return MaterialApp(
      home: UpdatWindowManager(
        appName: _packageInfo.appName,
        currentVersion: _packageInfo.version,
        getBinaryUrl: (version) {
          final binaryUrl =
              "https://api.github.com/repos/Tushandeep/test-app/releases/download/$version/${Platform.operatingSystem}-$version.$platformExtension";

          print("BinaryURL ------ $binaryUrl");

          return Future.value(binaryUrl);
        },
        getLatestVersion: () async {
          final Uri uri = Uri.parse("https://api.github.com/repos/Tushandeep/test-app/releases/latest");
          final response = await http.get(uri);

          final data = jsonDecode(response.body)['tag_name'];

          print("LatestVersion ------ $data");

          return data;
        },
        getChangelog: (_, __) async {
          final Uri uri = Uri.parse("https://api.github.com/repos/Tushandeep/test-app/releases/latest");
          final response = await http.get(uri);

          final releaseNotes = jsonDecode(response.body)['body'];

          print("Releases Notes ------ $releaseNotes");

          return releaseNotes;
        },
        callback: (status) {
          print(status);
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            controller.updateStatus.value = status.name;
          });
        },
        closeOnInstall: true,
        openOnDownload: true,
        child: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppController.instance;

    return Scaffold(
      backgroundColor: Colors.blue,
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
            const SizedBox(height: 20),
            const Text(
              "Hello from Tushandeep. This should be version = v0.1.1",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => Text(
                controller.updateStatus.value.toUpperCase(),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.black,
                ),
              ),
            ),
          ],
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

class AppController extends GetxController {
  static AppController instance =
      Get.isRegistered<AppController>() ? Get.find<AppController>() : Get.put<AppController>(AppController());

  final RxString updateStatus = RxString('idle');
}
