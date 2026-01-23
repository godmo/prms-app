import 'package:flutter_test/flutter_test.dart';
import 'package:prmsapp/utility/prms_data_check.dart';

void main() {
  group('PrmsDataCheck.isValidMachineId', () {
    test('accepts A + uppercase alphanumerics, total length 6-8', () {
      // expect(PrmsDataCheck.isValidMachineId('A12345'), isTrue); // 6
      // expect(PrmsDataCheck.isValidMachineId('A1B2C3'), isTrue); // 6
      // expect(PrmsDataCheck.isValidMachineId('A1234567'), isTrue); // 8
      // expect(PrmsDataCheck.isValidMachineId('A1B2C3D4'), isTrue); // 8

      // demo 01
      expect(PrmsDataCheck.isValidMachineId('APIMT1'), isTrue); // 8
      expect(PrmsDataCheck.isValidMachineId('APIMT2'), isTrue); // 8
      expect(PrmsDataCheck.isValidMachineId('APKRT1'), isTrue); // 8
      expect(PrmsDataCheck.isValidMachineId('APILT1'), isTrue); // 8
      expect(PrmsDataCheck.isValidMachineId('APART1'), isTrue); // 8
    });

    test('rejects invalid formats', () {
      expect(PrmsDataCheck.isValidMachineId('B12345'), isFalse); // not A*
      expect(PrmsDataCheck.isValidMachineId('A1234'), isFalse); // too short (5)
      expect(PrmsDataCheck.isValidMachineId('A12345678'), isFalse); // too long (9)
      expect(PrmsDataCheck.isValidMachineId('A12-345'), isFalse); // special char
      expect(PrmsDataCheck.isValidMachineId('A12_345'), isFalse); // special char
      expect(PrmsDataCheck.isValidMachineId('Aa2345'), isFalse); // lowercase
      expect(PrmsDataCheck.isValidMachineId('A1234*'), isFalse); // special char
    });
  });
}
