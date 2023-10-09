import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:test_app/updater/model.dart';

import 'updater/controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env File.
  await dotenv.load(fileName: ".env");

  ErrorWidget.builder = (error) => Text(error.exception.toString());

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.tealAccent,
      appBar: AppBar(
        backgroundColor: Colors.amberAccent,
        title: const Text("Test App"),
        actions: const [
          AppBarSettingsAction(),
          SizedBox(width: 30),
        ],
      ),
      body: Center(
        child: Container(
          height: 200,
          width: 200,
          color: Colors.red,
        ),
      ),
    );
  }
}

class AppBarSettingsAction extends StatelessWidget {
  const AppBarSettingsAction({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final GlobalKey settingsIconKey = GlobalKey();

    return IconButton(
      onPressed: () {
        if (settingsIconKey.currentContext == null) {
          return;
        }
        showDialog(
          context: context,
          barrierColor: Colors.black12,
          barrierDismissible: false,
          builder: (context) {
            final RenderBox box = settingsIconKey.currentContext!.findRenderObject() as RenderBox;
            final Size boxSize = box.size;
            final Offset boxPosition = box.localToGlobal(Offset.zero);

            const Size popupSize = Size(200, 400);

            final double top = boxPosition.dy + boxSize.height;
            final double left = boxPosition.dx + boxSize.width;

            final Size deviceSize = MediaQuery.of(context).size;

            return Stack(
              children: [
                Positioned(
                  top: top + 6,
                  left: left + popupSize.width > deviceSize.width ? left - popupSize.width : left - boxSize.width,
                  child: const SettingsPopupDialog(popupSize: popupSize),
                ),
              ],
            );
          },
        );
      },
      icon: Icon(
        key: settingsIconKey,
        Icons.settings,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

class SettingsPopupDialog extends StatefulWidget {
  const SettingsPopupDialog({
    super.key,
    required this.popupSize,
  });

  final Size popupSize;

  @override
  State<SettingsPopupDialog> createState() => _SettingsPopupDialogState();
}

class _SettingsPopupDialogState extends State<SettingsPopupDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final GlobalKey _columnKey = GlobalKey();
  final ValueNotifier<bool> isLarge = ValueNotifier<bool>(false);

  late UpdaterController updaterController;

  void popSizeNotifier(Duration _) async {
    final columnContext = _columnKey.currentContext;
    if (columnContext == null) return;
    final size = columnContext.size;
    if (size == null) return;
    isLarge.value = size.height > widget.popupSize.height;
  }

  @override
  void initState() {
    super.initState();

    updaterController = UpdaterController.instance;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 275),
      animationBehavior: AnimationBehavior.normal,
    );

    _scaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween(begin: 0, end: 1.15),
          weight: .8,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 1),
          weight: .2,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCirc,
      ),
    );

    SchedulerBinding.instance.addPostFrameCallback(popSizeNotifier);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        alignment: Alignment.topRight,
        scale: _scaleAnimation.value,
        child: TapRegion(
          onTapOutside: (e) => _controller.reverse().whenComplete(
                () => Navigator.pop(context),
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ListenableBuilder(
              listenable: isLarge,
              builder: (context, child) {
                return Container(
                  height: (isLarge.value) ? widget.popupSize.height : null,
                  width: widget.popupSize.width,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: SingleChildScrollView(
                    child: Column(
                      key: _columnKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: (isLarge.value) ? MainAxisSize.max : MainAxisSize.min,
                      children: [
                        Container(
                          width: widget.popupSize.width,
                          color: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                          child: Obx(
                            () {
                              final UpdaterStatus status = updaterController.status.value;
                              final String latestVersion = updaterController.latestVersion.value.toString();

                              late Widget widget;

                              const TextStyle style = TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                overflow: TextOverflow.visible,
                              );

                              if ([
                                UpdaterStatus.idle,
                                UpdaterStatus.checking,
                              ].contains(status)) {
                                widget = const Text(
                                  "Checking for updates...",
                                  style: style,
                                );
                              } else if (status == UpdaterStatus.available) {
                                widget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Update Available",
                                      style: style.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: "New Version: ",
                                            style: style,
                                          ),
                                          TextSpan(
                                            text: latestVersion,
                                            style: style.copyWith(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    PopUpTile(
                                      title: "Update",
                                      onPressed: updaterController.startUpdate,
                                    ),
                                  ],
                                );
                              } else if (status == UpdaterStatus.error) {
                                widget = PopUpTile(
                                  title: "Retry",
                                  onPressed: updaterController.retry,
                                );
                              } else if ([
                                UpdaterStatus.upToDate,
                                UpdaterStatus.dismissed,
                              ].contains(status)) {
                                widget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const SizedBox(height: 2),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "Version: ",
                                              style: style.copyWith(fontWeight: FontWeight.w400),
                                            ),
                                            TextSpan(
                                              text: updaterController.currentVersion.value,
                                              style: style.copyWith(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Divider(
                                      color: Colors.black45,
                                      thickness: .2,
                                      height: 0,
                                    ),
                                    const SizedBox(height: 6),
                                    PopUpTile(
                                      title: "Release Notes",
                                      textAlign: Alignment.center,
                                      backgroundColor: Colors.greenAccent.shade200,
                                      highlightColor: Colors.greenAccent.shade400,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => Dialog(
                                            child: Text(
                                              updaterController.releaseNotes.value ?? "",
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              } else if (status == UpdaterStatus.readyToInstall) {
                                widget = Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "Install Update",
                                            style: style.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            latestVersion,
                                            style: style.copyWith(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      PopUpTile(
                                        title: "Install Now",
                                        textAlign: Alignment.center,
                                        backgroundColor: Colors.greenAccent.shade200,
                                        highlightColor: Colors.greenAccent.shade400,
                                        onPressed: updaterController.launchInstaller,
                                      ),
                                    ],
                                  ),
                                );
                              } else if (status == UpdaterStatus.downloading) {
                                widget = Row(
                                  children: <Widget>[
                                    SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: CircularProgressIndicator.adaptive(
                                        strokeWidth: 2,
                                        value: (updaterController.progress.value != null)
                                            ? updaterController.progress.value! * 1.0
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Expanded(
                                      child: Text(
                                        "Downloading...",
                                        style: style,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.maxFinite,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: widget,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class PopUpTile extends StatelessWidget {
  const PopUpTile({
    super.key,
    required this.title,
    this.textAlign = Alignment.centerLeft,
    required this.onPressed,
    this.backgroundColor,
    this.highlightColor,
  });

  final String title;
  final AlignmentGeometry textAlign;
  final Color? backgroundColor, highlightColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onPressed,
        autofocus: true,
        borderRadius: BorderRadius.circular(4),
        focusColor: backgroundColor,
        hoverColor: highlightColor,
        highlightColor: highlightColor,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: textAlign,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
