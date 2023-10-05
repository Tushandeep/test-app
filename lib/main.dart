import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/repositories/update_repository.dart';
import 'package:updat/updat.dart';

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
    const UpdateRepository updateRepo = UpdateRepository();
    return MaterialApp(
      home: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.transparent),
          ),
          const HomePage(),
          UpdatWidget(
            appName: _packageInfo.appName,
            currentVersion: _packageInfo.version,
            getBinaryUrl: updateRepo.getBinaryUrl,
            getLatestVersion: updateRepo.getLatestVersion,
            getChangelog: updateRepo.getChangelog,
            callback: (status) {
              print(status);
              SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                controller.updateStatus.value = status.name;
              });
            },
            closeOnInstall: true,
          ),
        ],
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
    final ValueNotifier<String> versionListener = ValueNotifier<String>("N.A.");

    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/image1.jpeg",
                fit: BoxFit.fill,
                height: double.maxFinite,
                width: double.maxFinite,
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6, tileMode: TileMode.decal),
              child: Container(
                height: 400,
                width: 400,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.3),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
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
                    const Text(
                      "Hello from Tushandeep Dev.",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    MaterialButton(
                      onPressed: () async {
                        final SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.setString("key", _packageInfo.version);
                      },
                      color: Colors.red,
                      child: const Text(
                        "Set String",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: versionListener,
                      builder: (context, _) => Text(
                        "Previous Version: ${versionListener.value}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    MaterialButton(
                      onPressed: () async {
                        final SharedPreferences prefs = await SharedPreferences.getInstance();
                        versionListener.value = prefs.getString("key") ?? "N.A.";
                      },
                      color: Colors.red,
                      child: const Text(
                        "Get String",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppController extends GetxController {
  static AppController instance =
      Get.isRegistered<AppController>() ? Get.find<AppController>() : Get.put<AppController>(AppController());

  final RxString updateStatus = RxString('idle');
  final Rx<String?> binaryUrl = Rx<String?>(null);
  final Rx<String?> tagName = Rx<String?>(null);
  final Rx<String?> releaseNotes = Rx<String?>(null);
}
