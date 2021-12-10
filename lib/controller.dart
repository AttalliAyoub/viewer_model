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

  final _reday = Completer<void>();
  Future<void> get reday => _reday.future;

  set id(int id) {
    viewId = id;
    _channel = MethodChannel('method_viewer_model$id');
    _eventChannel = EventChannel('event_viewer_model$id');
    _streamSub = _eventChannel
        .receiveBroadcastStream()
        .listen(_listen, onError: _onError);
    _reday.complete();
  }

  late final int viewId;
  late final MethodChannel _channel;
  late final EventChannel _eventChannel;
  bool _transparentBackground;
  bool get transparentBackground {
    return _transparentBackground;
  }

  final _loadingController = StreamController<bool>(sync: true);
  Stream<bool> get loading => _loadingController.stream;
  late final StreamSubscription<dynamic> _streamSub;
  ViewerModelController({
    bool transparentBackground = false,
    Model? model,
  })  : _model = model,
        _transparentBackground = transparentBackground {
    _loadingController.add(model != null);
  }

  void _onError(dynamic err) {
    print(err);
  }

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
        _loadingController.add(data['status']);
        break;
      case "loadEarth":
        final data = event['data'];
        _loadingController.add(data['status']);
        break;
      default:
    }
  }

  void _dispose() {
    _loadingController.close();
    _streamSub.cancel();
  }

  Future<T> _loadingMidle<T>(Future<T> future) async {
    _loadingController.add(true);
    try {
      final r = await future;
      _loadingController.add(false);
      return r;
    } catch (err) {
      _loadingController.add(false);
      rethrow;
    }
  }

  Future<bool> setTransparentBackground(bool value) async {
    final result = await _channel
        .invokeMethod<bool>('transparentBackground', {'value': value});
    _transparentBackground = result!;
    return _transparentBackground;
  }

  Future<void> backgroundImage(String path) {
    _model = model;
    return _loadingMidle(
        _channel.invokeMethod<void>('backgroundImage', {'path': path}));
  }

  Future<void> loadTexture(Model model) {
    _model = model;
    return _loadingMidle(
        _channel.invokeMethod<void>('loadTexture', model.json));
  }

  Future<void> loadModel(Model model) {
    _model = model;
    return _loadingMidle(_channel.invokeMethod<void>('loadModel', model.json));
  }

  Future<void> loadEarth() {
    _model = model;
    return _loadingMidle(_channel.invokeMethod<void>('loadEarth'));
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
