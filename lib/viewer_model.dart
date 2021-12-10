library viewer_model;

import 'dart:async';
import 'dart:convert';

// import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math.dart';
// export 'package:vector_math/vector_math.dart';

part 'controller.dart';
part 'model.dart';

// typedef ViewCreatedCallBack = void Function(ViewerModelController controller);

class ViewerModel extends StatefulWidget {
  // final ViewCreatedCallBack? onViewCreated;
  // final Model? initialModel;
  final ViewerModelController controller;
  const ViewerModel({
    Key? key,
    required this.controller,
    // this.initialModel,
    // this.onViewCreated,
  }) : super(key: key);

  @override
  _ViewerModelState createState() => _ViewerModelState();
}

class _ViewerModelState extends State<ViewerModel> {
  final String viewType = 'com.ayoub.viewer_model';
  final creationParams = <String, dynamic>{};
  late int id;

  @override
  void initState() {
    super.initState();
    creationParams['initialModel'] = widget.controller.model?.json;
    creationParams['transparentBackground'] =
        widget.controller.transparentBackground;
  }

  @override
  void dispose() {
    widget.controller._dispose();
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    id = id;
    widget.controller.id = id;
  }

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (context, controller) {
        final ctl = controller as AndroidViewController;
        // ctl.viewId
        _onPlatformViewCreated(ctl.viewId);
        // ctl.
        return AndroidViewSurface(
          controller: ctl,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        final controller = PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () {
            params.onFocusChanged(true);
          },
        );
        controller
            .addOnPlatformViewCreatedListener(params.onPlatformViewCreated);
        controller.create();
        return controller;
      },
    );
  }
}
