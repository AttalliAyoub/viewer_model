import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viewer_model/viewer_model.dart';

void main() {
  const MethodChannel channel = MethodChannel('viewer_model');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  // test('getPlatformVersion', () async {
  //   expect(await ViewerModel.platformVersion, '42');
  // });
}
