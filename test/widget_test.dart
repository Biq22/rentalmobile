import 'package:flutter_test/flutter_test.dart';
import 'package:rentalmobile/core/format.dart';

void main() {
  test('format rupiah', () {
    expect(rupiah(350000), contains('350'));
  });

  test('label supir', () {
    expect(supirLabel('keduanya'), contains('supir'));
  });
}
