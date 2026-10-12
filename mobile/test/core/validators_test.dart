import 'package:flutter_test/flutter_test.dart';
import 'package:quickplate/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('ama'), isNotNull);
      expect(Validators.email('ama@example'), isNotNull);
      expect(Validators.email(' ama@example.com '), isNull);
    });

    test('requiredPassword accepts any non-empty value', () {
      expect(Validators.requiredPassword(''), isNotNull);
      expect(Validators.requiredPassword('abc'), isNull);
    });

    test('newPassword needs at least 8 characters', () {
      expect(Validators.newPassword('1234567'), isNotNull);
      expect(Validators.newPassword('12345678'), isNull);
    });

    test('confirmPassword compares with the current password', () {
      var password = 'secret123';
      final validate = Validators.confirmPassword(() => password);

      expect(validate('secret123'), isNull);
      expect(validate('secret124'), 'Passwords do not match.');

      password = 'changed99';
      expect(validate('secret123'), 'Passwords do not match.');
    });

    test('name', () {
      expect(Validators.name('  '), isNotNull);
      expect(Validators.name('A' * 51), isNotNull);
      expect(Validators.name('Ama Mensah'), isNull);
    });
  });
}
