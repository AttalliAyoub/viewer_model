part of viewer_model;

extension MyVector3 on Vector3 {
  Map<String, double> get json => {'x': x, 'y': y, 'z': z};
  Map<String, String> get shortJson => {'x': shortX, 'y': shortY, 'z': shortZ};
  String get shortX => x.toStringAsFixed(2);
  String get shortY => y.toStringAsFixed(2);
  String get shortZ => z.toStringAsFixed(2);
}

class ViewerModelController {
  Model? _model;
  Model? get model => _model;
  // set model(Model? m) {
  //   _model = m;
  //   if (m != null) {
  //     // return loadModel(m);
  //   }
  // }

  final int id;
  final MethodChannel _channel;
  final EventChannel _eventChannel;
  ViewerModelController._({
    required this.id,
    Model? model,
  })  : _channel = MethodChannel('method_viewer_model$id'),
        _eventChannel = EventChannel('event_viewer_model$id'),
        _model = model;

  // final _stream = _eventChannel.receiveBroadcastStream();

  Stream<dynamic> get loading {
    return _eventChannel.receiveBroadcastStream();
    /*
    .map((event) {
      print(event);
      return false;
    });
    */
  }

  Future<void> loadModel(Model model) {
    _model = model;
    return _channel.invokeMethod<void>('loadModel', model.json);
  }

  Future<void> loadEarth() {
    _model = model;
    return _channel.invokeMethod<void>('loadEarth');
  }

  Vector3 rotation = Vector3.zero();

  Future<void> rotate(Vector3 rotation) {
    this.rotation = rotation;
    return _channel.invokeMethod('rotate', rotation.json);
  }

  Vector3 position = Vector3.zero();

  Future<void> moveCam(Vector3 position) {
    this.position = position;
    return _channel.invokeMethod('moveCam', position.json);
  }

  Future<double> get _getRotation {
    return _channel
        .invokeMethod<double>('getRotation')
        .then((value) => value ?? 0.0);
  }
}
