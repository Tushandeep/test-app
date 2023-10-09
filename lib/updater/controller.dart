import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

import 'model.dart';
import 'repo.dart';

class UpdaterController extends GetxController {
  static UpdaterController instance = Get.isRegistered<UpdaterController>()
      ? Get.find<UpdaterController>()
      : Get.put<UpdaterController>(UpdaterController());

  final Rx<UpdaterStatus> status = Rx<UpdaterStatus>(UpdaterStatus.idle);
  UpdaterStatus? _previousStatus;

  /// Store these Variables in the .env File.
  late String _username, _repoName;

  final RxString currentVersion = RxString("");
  final Rx<Version?> latestVersion = Rx<Version?>(null);
  final Rx<String?> releaseNotes = Rx<String?>(null);
  final Rx<String?> _savedPath = Rx<String?>(null);

  late Directory _supportDir;

  /// Progress about the Release Download...
  final Rx<int?> progress = Rx<int?>(null);

  /// Package Info
  late PackageInfo _packageInfo;

  /// Updater Repo Instance...
  final UpdaterRepo _updaterRepo = UpdaterRepo();

  String get _operatingSystem => Platform.operatingSystem;
  String get _fileExtension {
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

  Future<void> _checkForUpdates() async {
    status.value = UpdaterStatus.checking;

    try {
      final (String, String)? result = await _updaterRepo.getLatestVersion(
        username: _username,
        repoName: _repoName,
      );

      if (result != null) {
        latestVersion.value = Version.parse(result.$1);

        if (latestVersion.value! > Version.parse(currentVersion.value)) {
          releaseNotes.value = result.$2;

          // Delete the Previous Version .exe File && Dir from the Location.
          final String previousVerisonDirPath =
              p.join(_supportDir.absolute.path, "app", "updates", _packageInfo.version);
          final Directory previousVersionDir = Directory(previousVerisonDirPath);
          if (previousVersionDir.existsSync()) {
            previousVersionDir.deleteSync(recursive: true);
          }

          // Check if user has already downloaded the latest version but has not installed it.
          // Get the file location to download the file to.
          _savedPath.value = await _getDownloadLatestReleaseFileLocation();

          // Check if the File exists of Latest Version (Pre-Downloaded).
          if (File(_savedPath.value!).existsSync()) {
            status.value = UpdaterStatus.readyToInstall;
          } else {
            status.value = UpdaterStatus.available;
          }
        } else {
          status.value = UpdaterStatus.upToDate;
        }
      }
    } catch (err) {
      _previousStatus = status.value;
      status.value = UpdaterStatus.error;
    }
  }

  void dismiss() {
    // Track Previous Status Value.
    final previousStatus = status.value;

    // Dismissed the Update or make it install for later.
    status.value = UpdaterStatus.dismissed;

    // Reassign the status variable value by previous status value.
    Future.delayed(const Duration(seconds: 2), () {
      status.value = previousStatus;
    });
  }

  Future<void> startUpdate() async {
    if (latestVersion.value == null) return;

    status.value = UpdaterStatus.downloading;

    // Get the URL to download the file from.
    final String url =
        "https://github.com/$_username/$_repoName/releases/download/${latestVersion.toString()}/$_operatingSystem-${latestVersion.toString()}.$_fileExtension";

    if (_savedPath.value != null) {
      // Download the file.

      try {
        await _updaterRepo.downloadRelease(
          _savedPath.value!,
          url,
          _packageInfo.appName,
          (progress) => this.progress.value = progress,
        );
      } catch (e) {
        _previousStatus = status.value;
        status.value = UpdaterStatus.error;
        return;
      }

      status.value = UpdaterStatus.readyToInstall;
    } else {
      _previousStatus = status.value;
      status.value = UpdaterStatus.error;

      Future.delayed(const Duration(seconds: 1), () {
        status.value = UpdaterStatus.upToDate;
      });
    }
  }

  Future<void> retry() async {
    if (_previousStatus != null) {
      if (_previousStatus == UpdaterStatus.readyToInstall) {
        await launchInstaller();
        return;
      }

      if (_previousStatus == UpdaterStatus.downloading) {
        await startUpdate();
        return;
      }
    }
  }

  Future<void> launchInstaller() async {
    if (status.value != UpdaterStatus.readyToInstall && status.value != UpdaterStatus.dismissed) {
      return;
    }
    // Open the file.
    try {
      // Save the Release notes of latest version.
      final String releaseNotesPath = p.join(_supportDir.absolute.path, "app", "updates", "notes.json");
      final File notesFile = File(releaseNotesPath);

      if (!notesFile.existsSync()) {
        notesFile.createSync(recursive: true);
        notesFile.writeAsStringSync(jsonEncode([]));
      }

      // Get the Data.
      final String data = notesFile.readAsStringSync();
      final List<dynamic> jsonData = jsonDecode(data);

      jsonData.add({
        "version": latestVersion.value.toString(),
        "notes": releaseNotes.value,
      });

      final String newData = jsonEncode(jsonData);
      notesFile.writeAsStringSync(newData);

      await _updaterRepo.openInstaller(
        _savedPath.value!,
        _packageInfo.appName,
      );
      // exit(0);
    } catch (e) {
      _previousStatus = status.value;
      status.value = UpdaterStatus.error;
    }
  }

  Future<String> _getDownloadLatestReleaseFileLocation() async {
    // Latest Version of the App.
    final String release = latestVersion.value.toString();

    // Construct the path of the file.
    final filePath = p.join(
      _supportDir.absolute.path,
      'app',
      'updates',
      release,
      '$_operatingSystem-$release.$_fileExtension',
    );

    return filePath;
  }

  @override
  void onInit() async {
    super.onInit();

    _packageInfo = await PackageInfo.fromPlatform();
    _supportDir = await getApplicationSupportDirectory();
    currentVersion.value = _packageInfo.version;
    status.value = UpdaterStatus.upToDate;
    _username = dotenv.get("COMPANY_USERNAME", fallback: "");
    _repoName = dotenv.get("COMPANY_REPONAME", fallback: "");

    await _checkForUpdates();
  }
}
