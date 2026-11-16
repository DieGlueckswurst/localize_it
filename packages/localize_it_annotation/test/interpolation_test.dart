import 'package:localize_it_annotation/localize_it_annotation.dart';
import 'package:test/test.dart';

void main() {
  const translations = {
    'Einladung': 'Invitation',
    'Einladung@@Anlass': 'Having guests',
    'Hallo {name}@@Push': 'Hi {name}',
  };

  setUp(() => LocalizeIt.translate = (key) => translations[key] ?? key);

  test('trIn looks up the string with its context', () {
    expect('Einladung'.trIn('Anlass'), 'Having guests');
    expect(LocalizeIt.translate('Einladung'), 'Invitation');
  });

  test('trIn replaces placeholders', () {
    expect('Hallo {name}'.trIn('Push', {'name': 'Anna'}), 'Hi Anna');
  });

  test('trIn falls back to the plain string, never the internal key', () {
    expect('Familie'.trIn('Anlass'), 'Familie');
  });

  test('trWithArgs still works', () {
    LocalizeIt.translate = (key) => key;
    expect('Hallo {name}'.trWithArgs({'name': 'Anna'}), 'Hallo Anna');
  });
}
