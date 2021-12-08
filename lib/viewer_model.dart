// import 'dart:async';

// import 'package:flutter/services.dart';

// class ViewerModel {
//   static const MethodChannel _channel = MethodChannel('viewer_model');

//   static Future<String?> get platformVersion async {
//     final String? version = await _channel.invokeMethod('getPlatformVersion');
//     return version;
//   }
// }

// import 'dart:async';
library viewer_model;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math.dart';
// export 'package:vector_math/vector_math.dart';

part 'controller.dart';
part 'model.dart';

typedef ViewCreatedCallBack = void Function(ViewerModelController controller);

class ViewerModel extends StatefulWidget {
  final ViewCreatedCallBack? onViewCreated;
  final Model? initialModel;
  const ViewerModel({
    Key? key,
    this.initialModel,
    this.onViewCreated,
  }) : super(key: key);

  @override
  _ViewerModelState createState() => _ViewerModelState();
}

class _ViewerModelState extends State<ViewerModel> {
  final String viewType = 'com.ayoub.viewer_model';
  final creationParams = <String, dynamic>{};
  late int id;
  late ViewerModelController controller;

  @override
  void initState() {
    super.initState();
    creationParams['initialModel'] = widget.initialModel?.json;
  }

  void _onPlatformViewCreated(int id) {
    id = id;
    controller = ViewerModelController._(id: id, model: widget.initialModel);
    if (widget.onViewCreated != null) widget.onViewCreated!(controller);
  }

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: viewType,
      // gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
      //   Factory<OneSequenceGestureRecognizer>(
      //     () => EagerGestureRecognizer(),
      //   ),
      // },
      onPlatformViewCreated: _onPlatformViewCreated,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
