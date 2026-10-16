import 'package:flutter_test/flutter_test.dart';
import 'package:union_interface/main.dart';

void main() {
  test('App widget smoke test', () {
    const app = MyApp();
    expect(app, isNotNull);
  });
}

