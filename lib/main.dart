import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
            child: Container(
              color: Colors.transparent,
            ),
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

// Widget showChipDialogFunction({
//   required String appVersion,
//   required void Function() checkForUpdate,
//   required BuildContext context,
//   required void Function() dismissUpdate,
//   required String? latestVersion,
//   required Future<void> Function() launchInstaller,
//   required void Function() openDialog,
//   required void Function() startUpdate,
//   required UpdatStatus status,
// }) {
//   return
// }

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppController.instance;

    return Scaffold(
      backgroundColor: Colors.yellow,
      body: Center(
        child: Obx(
          () => Column(
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
              Text(
                controller.updateStatus.value.toUpperCase(),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Binary URL: ${controller.binaryUrl.value}",
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Tag Name: ${controller.tagName.value?.toUpperCase()}",
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Releases Notes: ${controller.releaseNotes.value}",
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.black,
                ),
              ),
            ],
          ),
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
