part of viewer_model;

extension MyVector3 on Vector3 {
  Map<String, double> get json => {'x': x, 'y': y, 'z': z};
  Map<String, String> get shortJson => {'x': shortX, 'y': shortY, 'z': shortZ};
  String get shortX => x.toStringAsFixed(2);
  String get shortY => y.toStringAsFixed(2);
  String get shortZ => z.toStringAsFixed(2);

  static Vector3 fromJSON(dynamic data) {
    return Vector3(data['x'], data['y'], data['z']);
  }
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
  late final StreamSubscription<dynamic> _streamSub;
  ViewerModelController._({
    required this.id,
    Model? model,
  })  : _channel = MethodChannel('method_viewer_model$id'),
        _eventChannel = EventChannel('event_viewer_model$id'),
        // _stream = _eventChannel.receiveBroadcastStream(),
        _model = model {
    _streamSub = _eventChannel.receiveBroadcastStream().listen(_listen);
  }
  // late final Stream<bool> loading;

  void _listen(dynamic event) {
    switch (event['event']) {
      case "initScene":
        print('initScene');
        break;
      case "cameraPosition":
        final data = json.decode(event['data']);
        camPosition = MyVector3.fromJSON(data);
        break;
      case "OffsetsChanged":
        final data = event['data'];
        print(data);
        break;
      case "touch":
        final data = json.decode(event['data']);
        print(data);
        break;
      case "loading":
        final data = event['data'];
        print(data);
        break;
      case "loadEarth":
        final data = event['data'];
        print(data);
        break;
      default:
    }
  }

  void _dispose() {
    _streamSub.cancel();
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

  Future<void> rotate(Vector3? rotation) async {
    if (rotation == null) return;
    this.rotation = rotation;
    return _channel.invokeMethod('rotate', rotation.json);
  }

  Vector3 camPosition = Vector3(0, 0, 4.2);

  Future<void> moveCam(Vector3? position) async {
    if (position == null) return;
    camPosition = position;
    return _channel.invokeMethod('moveCam', camPosition.json);
  }

  // Future<double> get _getRotation {
  //   return _channel
  //       .invokeMethod<double>('getRotation')
  //       .then((value) => value ?? 0.0);
  // }
}
