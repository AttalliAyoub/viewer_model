import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/rendering.dart';
import 'package:viewer_model/viewer_model.dart';
import 'package:download_assets/download_assets.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final downloadAssetsController = DownloadAssetsController();

  Future _refresh() async {
    await downloadAssetsController.clearAssets();
    await _downloadAssets();
  }

  void _showMessage({
    required String message,
    String label = 'OK',
    VoidCallback? onPressed,
  }) {
    onPressed ??= () {};
    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(label: label, onPressed: onPressed),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  ViewerModelController? viewer3dCtl;

  Future _downloadAssets() async {
    final assetsDownloaded =
        await downloadAssetsController.assetsDirAlreadyExists();
    if (assetsDownloaded) {
      _showMessage(message: 'your assets is Downloaded');
      return;
    }
    try {
      await downloadAssetsController.startDownload(
          assetsUrl:
              "https://github.com/edjostenes/download_assets/raw/master/assets.zip",
          onProgress: (progressValue) {
            _showMessage(
                message: "Downloading - ${progressValue.toStringAsFixed(2)}");
          },
          onComplete: () {
            _showMessage(
                message:
                    "Download completed\nClick in refresh button to force download");
          },
          onError: (exception) {
            _showMessage(message: "Error: ${exception.toString()}");
          });
    } on DownloadAssetsException catch (e) {
      _showMessage(message: e.toString());
    }
  }

  Future<void> loading = Future<void>.value();

  void pickFile() async {
    print(downloadAssetsController.assetsDir);
    final list = Directory(downloadAssetsController.assetsDir).listSync();
    // final list = await Download.assetsDir.then((d) => d.listSync());
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Load a file'),
            // children: dir.listSync().map((file) {
            //   return ListTile(
            //     title: Text(path.basename(file.path)),
            //     subtitle: Text(file.path),
            //   );
            // }).toList(),
            children: [
              for (final file in list)
                ListTile(
                  leading: const Icon(Icons.view_in_ar),
                  title: const Text('Model'),
                  subtitle: Text(path.basename(file.path)),
                  // subtitle: Text(file.path),
                  onTap: () async {
                    if (viewer3dCtl == null) return;
                    Navigator.of(context).pop();
                    // debugPrint(file.path);
                    setState(() {
                      loading = viewer3dCtl!
                          .loadModel(Model(path: file.path))
                          .then((value) {
                        _showMessage(
                            message: '${path.basename(file.path)} loaded');
                      }).catchError((err) {
                        _showMessage(message: '$err');
                      });
                    });
                  },
                ),
              ListTile(
                leading: const Icon(Icons.view_in_ar),
                title: const Text('Model'),
                subtitle: const Text('Sphere'),
                onTap: () async {
                  if (viewer3dCtl == null) return;
                  Navigator.of(context).pop();
                  setState(() {
                    loading = viewer3dCtl!.loadEarth().then((value) {
                      _showMessage(message: 'Earth loaded');
                    }).catchError((err) {
                      _showMessage(message: '$err');
                    });
                  });
                },
              ),
            ],
          );
        });
  }

  Model? get initialModel {
    final file = File(
        '/data/user/0/com.ayoub.viewer_model_example/app_flutter/assets/T-shirt_3dmodel.obj');
    if (file.existsSync()) return Model(path: file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              child: const Icon(Icons.refresh),
              onPressed: () {
                _showMessage(
                    message: 'Are you shure you want to refresh',
                    label: 'Refresh',
                    onPressed: _refresh);
              },
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              child: const Icon(Icons.upload_file),
              onPressed: pickFile,
            ),
          ],
        ),
        body: Stack(
          children: [
            ViewerModel(
              initialModel: initialModel,
              onViewCreated: (ctl) {
                viewer3dCtl = ctl;
                _downloadAssets();
              },
            ),
            // Positioned(
            //   top: 0,
            //   left: 0,
            //   right: 0,
            //   height: 100,
            //   child: StreamBuilder(
            //     stream: viewer3dCtl?.loading,
            //     builder: (context, snap) {
            //       debugPrint('${snap.data}');
            //       return Container(
            //         color: Colors.green,
            //         padding: const EdgeInsets.all(10),
            //         child: Text('${snap.data}'),
            //       );
            //     },
            //   ),
            // ),
            FormField<double>(
              initialValue: 1.0,
              builder: (state) {
                return GestureDetector(
                  // onPanUpdate: (details) {
                  //   viewer3dCtl.rotation.y -= details.delta.dx;
                  //   viewer3dCtl.rotation.z -= details.delta.dy;
                  //   viewer3dCtl.rotate(viewer3dCtl.rotation);
                  // },
                  onHorizontalDragUpdate: (details) {
                    viewer3dCtl?.rotation.y -= details.primaryDelta ?? 0;
                    viewer3dCtl?.rotate(viewer3dCtl?.rotation);
                  },
                  onScaleStart: (details) {
                    state.didChange(1.0);
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      viewer3dCtl?.camPosition.z -=
                          details.scale - (state.value ?? 0);
                      if ((viewer3dCtl?.camPosition.z ?? 0) < 0.1) {
                        viewer3dCtl?.camPosition.z = .1;
                      }
                      viewer3dCtl?.moveCam(viewer3dCtl?.camPosition);
                      state.didChange(details.scale);
                    });
                  },
                );
              },
            ),
            Center(
              child: FutureBuilder(
                future: loading,
                builder: (context, snap) {
                  final waiting =
                      snap.connectionState == ConnectionState.waiting;
                  if (waiting) {
                    return const CircularProgressIndicator();
                  }
                  return Container();
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cam Pos: ${viewer3dCtl?.camPosition.shortJson}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  Text(
                    'Obj rotation: ${viewer3dCtl?.rotation.shortJson}',
                    style: const TextStyle(color: Colors.red),
                  )
                ],
              ),
            ),
            /*
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: -360,
                    max: 360,
                    value: camPos.x,
                    label: 'Cam x',
                    onChanged: (double value) {
                      setState(() {
                        camPos.x = value;
                      });
                      viewer3dCtl.moveCam(camPos);
                    },
                  ),
                  Slider(
                    min: -360,
                    max: 360,
                    value: camPos.y,
                    label: 'Cam y',
                    onChanged: (double value) {
                      setState(() {
                        camPos.y = value;
                      });
                      viewer3dCtl.moveCam(camPos);
                    },
                  ),
                  Slider(
                    min: -360,
                    max: 360,
                    value: camPos.z,
                    label: 'Cam z',
                    onChanged: (double value) {
                      setState(() {
                        camPos.z = value;
                      });
                      debugPrint('${camPos.z}');
                      viewer3dCtl.moveCam(camPos);
                    },
                  ),
                  Slider(
                    min: -360,
                    max: 360,
                    value: roationValue,
                    label: 'object y rote',
                    onChanged: (double value) {
                      setState(() {
                        roationValue = value;
                      });
                      viewer3dCtl.rotate(Vector3(0, value, 0));
                    },
                  ),
                ],
              ),
            ),
          */
          ],
        ));
  }
}
