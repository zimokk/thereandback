import 'package:intl/date_symbol_data_local.dart';
import 'package:test/test.dart';
import 'package:thereandback/core/formatters.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  group('formatDistance (§5.4 boundaries)', () {
    test('below 1000 m renders whole meters', () {
      final result = formatDistance(999);
      expect(result.value, '999');
      expect(result.unit, DistanceUnit.meters);
    });

    test('exactly 1000 m switches to kilometers with two decimals', () {
      final result = formatDistance(1000);
      expect(result.value, '1.00');
      expect(result.unit, DistanceUnit.kilometers);
    });

    test('between 1 km and 100 km keeps two decimals', () {
      final result = formatDistance(5230);
      expect(result.value, '5.23');
      expect(result.unit, DistanceUnit.kilometers);
    });

    test('exactly 100 km still uses two decimals', () {
      final result = formatDistance(100000);
      expect(result.value, '100.00');
      expect(result.unit, DistanceUnit.kilometers);
    });

    test('above 100 km rounds to whole kilometers', () {
      final result = formatDistance(2853400);
      expect(result.value, '2853');
      expect(result.unit, DistanceUnit.kilometers);
    });

    test('zero meters is a valid whole-meter reading', () {
      final result = formatDistance(0);
      expect(result.value, '0');
      expect(result.unit, DistanceUnit.meters);
    });
  });

  group('formatSignedDistance (§5.3, §5.4)', () {
    test('a friend ahead renders with a leading plus', () {
      final result = formatSignedDistance(229000);
      expect(result.value, '+229');
      expect(result.unit, DistanceUnit.kilometers);
    });

    test('a friend behind renders with a leading minus, on the magnitude', () {
      final result = formatSignedDistance(-40);
      expect(result.value, '-40');
      expect(result.unit, DistanceUnit.meters);
    });

    test('a tie (zero delta) renders as a plain plus-zero', () {
      final result = formatSignedDistance(0);
      expect(result.value, '+0');
      expect(result.unit, DistanceUnit.meters);
    });

    test('follows the same §5.4 precision boundaries as formatDistance', () {
      final result = formatSignedDistance(-5230);
      expect(result.value, '-5.23');
      expect(result.unit, DistanceUnit.kilometers);
    });
  });

  group('formatEtaDate', () {
    test('null eta renders as null (caller shows a dash, §5.3)', () {
      expect(formatEtaDate(null, localeName: 'en'), isNull);
    });

    test('a real eta renders a locale date string', () {
      final formatted = formatEtaDate(DateTime(2026, 9, 1), localeName: 'en');
      expect(formatted, isNotNull);
      expect(formatted, contains('2026'));
    });
  });
}
