import 'package:flutter_document_picker/flutter_document_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:viewer_model/viewer_model.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_p;

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
  final viewerModelController =
      ViewerModelController(transparentBackground: false);

  @override
  void initState() {
    super.initState();
    getPermission(Permission.storage).then((value) async {
      await getPermission(Permission.manageExternalStorage);
    });
  }

  Future<void> getPermission(Permission permission) async {
    final status = await Permission.storage.status;
    if (status == PermissionStatus.granted) return;
    if (status == PermissionStatus.permanentlyDenied) {
      await openAppSettings();
      await getPermission(permission);
      return;
    }
    await permission.request();
    await getPermission(permission);
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

  void pickModel() async {
    final path = await FlutterDocumentPicker.openDocument();
    if (path == null || path.isEmpty) return;
    viewerModelController.loadModel(Model(path: path)).then((value) {
      _showMessage(message: '${path_p.basename(path)} is loaded');
    }).catchError((err) {
      _showMessage(message: '$err');
    });
  }

  void loadEarth() async {
    viewerModelController.loadEarth().then((value) {
      _showMessage(message: 'Earth is loaded');
    }).catchError((err) {
      _showMessage(message: '$err');
    });
  }

  void pickTexture() async {
    final path = await FlutterDocumentPicker.openDocument();
    if (path == null || path.isEmpty) return;
    viewerModelController
        .loadTexture(Model(
      path: viewerModelController.model!.path,
      texture: path,
    ))
        .then((value) {
      _showMessage(message: '${path_p.basename(path)} is loaded');
    }).catchError((err) {
      _showMessage(message: '$err');
    });
  }

  void backgroundImage() async {
    final path = await FlutterDocumentPicker.openDocument();
    if (path == null || path.isEmpty) return;
    viewerModelController.backgroundImage(path).then((value) {
      _showMessage(message: '${path_p.basename(path)} is loaded');
    }).catchError((err) {
      _showMessage(message: '$err');
    });
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
            heroTag: 'loadEarth',
            child: const Icon(Icons.animation_outlined),
            onPressed: loadEarth,
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'backgroundImage',
            child: const Icon(Icons.wallpaper),
            onPressed: backgroundImage,
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'pickTexture',
            child: const Icon(Icons.texture),
            onPressed: pickTexture,
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'pickModel',
            child: const Icon(Icons.view_in_ar),
            onPressed: pickModel,
          ),
        ],
      ),
      backgroundColor: Colors.red,
      body: Column(
        children: [
          Text(
            'Cam Pos: ${viewerModelController.camPosition.shortJson}',
            style: const TextStyle(color: Colors.red),
          ),
          Text(
            'Obj rotation: ${viewerModelController.rotation.shortJson}',
            style: const TextStyle(color: Colors.red),
          ),
          Row(
            children: [
              Switch(
                value: viewerModelController.transparentBackground,
                onChanged: (value) {
                  viewerModelController
                      .setTransparentBackground(value)
                      .then((value) => setState(() {}));
                },
              ),
              StreamBuilder<bool>(
                stream: viewerModelController.loading,
                builder: (context, snap) {
                  final laoding = snap.data ?? false;
                  if (laoding) {
                    return const CircularProgressIndicator();
                  }
                  return Container();
                },
              ),
            ],
          ),
          Expanded(
            child: ViewerModel(
              controller: viewerModelController,
            ),
          ),
          /*
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
                    viewerModelController.rotation.y -=
                        details.primaryDelta ?? 0;
                    viewerModelController
                        .rotate(viewerModelController.rotation);
                  },
                  onScaleStart: (details) {
                    state.didChange(1.0);
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      viewerModelController.camPosition.z -=
                          details.scale - (state.value ?? 0);
                      if (viewerModelController.camPosition.z < 0.1) {
                        viewerModelController.camPosition.z = .1;
                      }
                      viewerModelController
                          .moveCam(viewerModelController.camPosition);
                      state.didChange(details.scale);
                    });
                  },
                );
              },
            ),*/
        ],
      ),
      /*    
        Stack(
          children: [
            // Container(color: Colors.red),
            
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
        )
        
  */
    );
  }
}
